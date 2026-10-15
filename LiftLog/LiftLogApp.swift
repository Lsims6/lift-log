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
        let boot = "window.__LIFTLOG__ = \(Store.load());"
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

    // Messages from the page: {type: "save", json} and {type: "export", filename, csv}.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "save":
            if let json = body["json"] as? String { Store.save(json) }
        case "export":
            guard let csv = body["csv"] as? String else { return }
            let name = (body["filename"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "lift-log.csv"
            share(csv: csv, filename: name)
        default:
            break
        }
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
