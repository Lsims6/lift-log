import Security
import SwiftUI
import UIKit
import WebKit

@main
struct LiftLogApp: App {
    init() {
        // UI tests launch with -resetData to start from an empty log.
        if CommandLine.arguments.contains("-resetData") { Store.reset() }
    }

    var body: some Scene {
        WindowGroup {
            LiftLogWebView()
                .ignoresSafeArea()
                .background(Color(uiColor: .liftLogBackground).ignoresSafeArea())
        }
    }
}

extension UIColor {
    /// Matches the page's --bg token in light and dark mode, so there is no flash behind the page.
    static let liftLogBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x11 / 255, green: 0x14 / 255, blue: 0x18 / 255, alpha: 1)
            : UIColor(red: 0xEE / 255, green: 0xF0 / 255, blue: 0xF3 / 255, alpha: 1)
    }
}

/// Saves the whole log as one JSON file in the app's Documents folder, keeping the previous
/// version as a backup. The file is small (a year of workouts is well under a megabyte).
enum Store {
    private static var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var fileURL: URL { docs.appendingPathComponent("lift-log.json") }
    static var backupURL: URL { docs.appendingPathComponent("lift-log.backup.json") }
    private static var backedUpThisLaunch = false

    /// The saved log as JSON text, or "null" when there is none yet. Falls back to the backup if the main file is unreadable.
    static func load() -> String {
        for url in [fileURL, backupURL] {
            if let data = try? Data(contentsOf: url),
               (try? JSONSerialization.jsonObject(with: data)) != nil,
               let text = String(data: data, encoding: .utf8) {
                return text
            }
        }
        return "null"
    }

    static func save(_ json: String) {
        let data = Data(json.utf8)
        // Never overwrite good data with something unreadable.
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else { return }
        let fm = FileManager.default
        if !backedUpThisLaunch, fm.fileExists(atPath: fileURL.path) {
            try? fm.removeItem(at: backupURL)
            try? fm.copyItem(at: fileURL, to: backupURL)
            backedUpThisLaunch = true
        }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    static func reset() {
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: backupURL)
    }
}

/// The Anthropic API key for food estimates, kept in the iPhone's Keychain (never in the log file or exports).
enum KeyStore {
    private static let base: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.lsims6.liftlog.anthropic",
        kSecAttrAccount as String: "api-key",
    ]

    static func read() -> String? {
        var query = base
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data, let key = String(data: data, encoding: .utf8), !key.isEmpty else { return nil }
        return key
    }

    static func set(_ key: String) {
        SecItemDelete(base as CFDictionary)
        guard !key.isEmpty else { return }
        var item = base
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static var hasKey: Bool { read() != nil }
}

/// Sends a food-estimate request to the Claude API. The page builds the request body; this side only adds the
/// key and always posts to the same fixed address, so the page can't send the key anywhere else.
enum ClaudeAPI {
    static let url = URL(string: "https://api.anthropic.com/v1/messages")!

    static func send(body: String, done: @escaping (_ status: Int, _ body: String) -> Void) {
        guard let key = KeyStore.read() else {
            done(0, "Add your Anthropic API key in the settings below first, or tap Enter it myself.")
            return
        }
        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = Data(body.utf8)
        URLSession.shared.dataTask(with: req) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            DispatchQueue.main.async { done(status, text) }
        }.resume()
    }
}

struct LiftLogWebView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController { WebViewController() }
    func updateUIViewController(_ controller: WebViewController, context: Context) {}
}

final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        let content = WKUserContentController()

        installBootScript(on: content)
        content.add(WeakMessageHandler(self), name: "liftlog")
        config.userContentController = content
        config.dataDetectorTypes = []

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .liftLogBackground
        webView.scrollView.backgroundColor = .liftLogBackground
        webView.scrollView.contentInsetAdjustmentBehavior = .never // the page pads itself with env(safe-area-inset-*)
        webView.allowsLinkPreview = false
        view = webView
    }

    /// Hands the saved log to the page before any of its scripts run. Rebuilt before every reload,
    /// so a reloaded page always starts from what is on disk now, never from a stale copy.
    private func installBootScript(on content: WKUserContentController) {
        content.removeAllUserScripts()
        let boot = "window.__LIFTLOG__ = \(Store.load()); window.__LIFTLOG_KEY__ = \(KeyStore.hasKey);"
        content.addUserScript(WKUserScript(source: boot, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") else {
            assertionFailure("Web/index.html is missing from the app bundle")
            return
        }
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    // Messages from the page: {type: "save", json}, {type: "export", filename, csv},
    // {type: "setKey", key} (empty removes it) and {type: "ai", id, body} for a food estimate.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "save":
            if let json = body["json"] as? String { Store.save(json) }
        case "export":
            guard let csv = body["csv"] as? String else { return }
            let name = (body["filename"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "lift-log.csv"
            share(csv: csv, filename: name)
        case "setKey":
            KeyStore.set(((body["key"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
            callPage("__keyStatus", KeyStore.hasKey)
        case "ai":
            guard let request = body["body"] as? String else { return }
            let id = body["id"] ?? 0
            ClaudeAPI.send(body: request) { [weak self] status, text in
                self?.callPage("__aiResult", ["id": id, "status": status, "body": text])
            }
        default:
            break
        }
    }

    /// Calls window.<name>(value) on the page, passing the value as JSON.
    private func callPage(_ name: String, _ value: Any) {
        guard let data = try? JSONSerialization.data(withJSONObject: [value], options: [.fragmentsAllowed]),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.\(name) && window.\(name)(...\(json))", completionHandler: nil)
    }

    private func share(csv: String, filename: String) {
        let safeName = filename.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
        do {
            try Data(csv.utf8).write(to: url, options: .atomic)
        } catch {
            return
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(sheet, animated: true)
    }

    // Keep the app on its own page: anything else (there are no outside links today) opens in Safari.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, url.isFileURL || url.scheme == "about" || url.scheme == "blob" {
            decisionHandler(.allow)
        } else {
            if let url = action.request.url { UIApplication.shared.open(url) }
            decisionHandler(.cancel)
        }
    }

    // If iOS ever reclaims the web content process, reload so the app isn't left blank.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        installBootScript(on: webView.configuration.userContentController)
        webView.reload()
    }
}

/// WKUserContentController holds its handlers strongly; this breaks the retain cycle.
final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
