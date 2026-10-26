import Security
import SwiftUI
import UIKit
import WebKit
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
struct LiftLogApp: App {
    init() {
        // UI tests launch with -resetData to start from an empty log.
        if CommandLine.arguments.contains("-resetData") { Store.reset() }
        FoodAI.removeOldKey()
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

/// Food estimates from Apple's on-device model (Apple Intelligence, iOS 26 and later). Everything runs on the
/// iPhone: no account, no key, no cost, and nothing is sent anywhere.
enum FoodAI {
    /// What the page needs to know: "ready", "notEnabled" (Apple Intelligence is off), "notReady" (still
    /// downloading), "notEligible" (this iPhone can't run it) or "unsupported" (iOS older than 26).
    static var status: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            if case .available = availability { return "ready" }
            if case .unavailable(.appleIntelligenceNotEnabled) = availability { return "notEnabled" }
            if case .unavailable(.modelNotReady) = availability { return "notReady" }
            if case .unavailable(.deviceNotEligible) = availability { return "notEligible" }
        }
        #endif
        return "unsupported"
    }

    static func message(for status: String) -> String {
        switch status {
        case "notEnabled": return "Turn on Apple Intelligence in the iPhone's Settings first, or tap Enter it myself."
        case "notReady": return "Apple Intelligence is still getting ready on this iPhone. Try again in a bit, or tap Enter it myself."
        default: return "Estimates need Apple Intelligence on this iPhone. Tap Enter it myself instead."
        }
    }

    static let instructions = """
        You estimate the calories and protein in food someone says they ate.
        Split the description into separate items: each sandwich, entree, side, sauce and drink gets its own item.
        For chain restaurant menu items, use that chain's published nutrition numbers for the standard size unless a size or count is given. A "meal" or "combo" includes its usual side and drink.
        When menu numbers are listed with the request and one matches an item, use those numbers exactly.
        For home-made or generic food, assume one typical portion unless amounts are given.
        Diet sodas, water, unsweetened tea and black coffee are 0 calories.
        Round calories to the nearest 10 and protein to the nearest gram.
        Give each item a short name that includes the restaurant (if any) and the portion.
        """

    /// Answers with ["items": [[name, calories, protein]], "note": String] or ["error": String], on the main thread.
    static func estimate(text: String, reference: String, done: @escaping ([String: Any]) -> Void) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            Task { @MainActor in done(await run(text: text, reference: reference)) }
            return
        }
        #endif
        done(["error": message(for: "unsupported")])
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func run(text: String, reference: String) async -> [String: Any] {
        let now = status
        guard now == "ready" else { return ["error": message(for: now)] }
        var prompt = "What I ate: \(text)"
        if !reference.isEmpty {
            prompt += "\n\nMenu numbers from the app that may match:\n\(reference)"
        }
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: FoodEstimate.self)
            let items: [[String: Any]] = response.content.items.map {
                ["name": $0.name, "calories": $0.calories, "protein": $0.protein]
            }
            return ["items": items, "note": response.content.note]
        } catch let error as LanguageModelSession.GenerationError {
            if case .guardrailViolation = error {
                return ["error": "Apple's model wouldn't estimate that. Try wording it differently, or tap Enter it myself."]
            }
            if case .exceededContextWindowSize = error {
                return ["error": "That's too long to estimate in one go. Try a shorter description."]
            }
            if case .unsupportedLanguageOrLocale = error {
                return ["error": "Apple's model doesn't support this iPhone's language yet. Tap Enter it myself instead."]
            }
            return ["error": "The estimate failed. Try again, or tap Enter it myself."]
        } catch {
            return ["error": "The estimate failed. Try again, or tap Enter it myself."]
        }
    }
    #endif

    /// Earlier versions kept an Anthropic API key in the Keychain; clear it out so nothing is left behind.
    static func removeOldKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.lsims6.liftlog.anthropic",
        ]
        SecItemDelete(query as CFDictionary)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct FoodEstimate {
    @Guide(description: "Each separate food or drink that was eaten, one entry per item")
    var items: [FoodEstimateItem]
    @Guide(description: "One short sentence about any portion or size you had to assume, or an empty string")
    var note: String
}

@available(iOS 26.0, *)
@Generable
struct FoodEstimateItem {
    @Guide(description: "Short name with the restaurant (if any) and portion, e.g. Chick-fil-A chicken biscuit")
    var name: String
    @Guide(description: "Estimated calories, rounded to the nearest 10")
    var calories: Int
    @Guide(description: "Estimated grams of protein")
    var protein: Int
}
#endif

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
        let info = Bundle.main.infoDictionary ?? [:]
        let version = "\(info["CFBundleShortVersionString"] as? String ?? "?") (build \(info["CFBundleVersion"] as? String ?? "?"))"
        let boot = "window.__LIFTLOG__ = \(Store.load()); window.__LIFTLOG_AI__ = \"\(FoodAI.status)\"; window.__LIFTLOG_VERSION__ = \"\(version)\";"
        content.addUserScript(WKUserScript(source: boot, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") else {
            assertionFailure("Web/index.html is missing from the app bundle")
            return
        }
        webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        // Apple Intelligence can be turned on or finish downloading while the app is in the background.
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appBecameActive() {
        callPage("__aiStatus", FoodAI.status)
    }

    // Messages from the page: {type: "save", json}, {type: "export", filename, csv},
    // and {type: "estimate", id, text, reference} for a food estimate from the on-device model.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "save":
            if let json = body["json"] as? String { Store.save(json) }
        case "export":
            guard let csv = body["csv"] as? String else { return }
            let name = (body["filename"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "lift-log.csv"
            share(csv: csv, filename: name)
        case "estimate":
            guard let text = body["text"] as? String else { return }
            let id = body["id"] ?? 0
            FoodAI.estimate(text: text, reference: body["reference"] as? String ?? "") { [weak self] result in
                self?.callPage("__aiResult", result.merging(["id": id]) { _, new in new })
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
