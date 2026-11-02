import CryptoKit
import Foundation

/// Live updates for the page. Almost all of Lift Log is the web page in LiftLog/Web; the GitHub Pages deploy
/// publishes it with a version.json (commit, time, a checksum per file). The app looks there when it opens or
/// comes back to the front, downloads a newer page, checks every file against its checksum, and keeps it in
/// Application Support. A TestFlight build is only needed when this Swift code changes.
///
/// Safety:
/// - The log itself lives in Documents (see Store), never in the page, so swapping pages can't touch it.
/// - A downloaded page is only used if it's newer than the copy built into the app, and only if it says it
///   works with this app (its minNative is at most NATIVE_API).
/// - If a downloaded page doesn't report back within a few seconds of loading, it's marked bad and the
///   built-in page is shown instead.
enum LiveWeb {
    /// What this app can do for the page. Pages declare the oldest app they work with in
    /// <meta name="liftlog-min-native">; bump both together when the page needs something new from here.
    /// 2: live updates, the native tab bar.
    static let NATIVE_API = 2
    static let site = URL(string: "https://lsims6.github.io/lift-log/")!

    /// UI tests always use the page built into the app.
    static var disabled: Bool { CommandLine.arguments.contains("-noLiveUpdate") }

    struct Info: Decodable {
        let sha: String
        let time: Int
        let minNative: Int
        let files: [File]
        struct File: Decodable {
            let path: String
            let sha256: String
            let size: Int
        }
        var short: String { String(sha.prefix(7)) }
    }

    private static var root: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LiveWeb", isDirectory: true)
    }
    static var liveDir: URL { root.appendingPathComponent("current", isDirectory: true) }
    static var bundledDir: URL? { Bundle.main.url(forResource: "Web", withExtension: nil) }

    static func info(in dir: URL?) -> Info? {
        guard let dir, let data = try? Data(contentsOf: dir.appendingPathComponent("version.json")) else { return nil }
        return try? JSONDecoder().decode(Info.self, from: data)
    }

    /// A downloaded page that failed to start; never used or downloaded again.
    private static let badKey = "LiveWeb.badSha"
    static var badSha: String? {
        get { UserDefaults.standard.string(forKey: badKey) }
        set { UserDefaults.standard.set(newValue, forKey: badKey) }
    }

    struct Choice {
        let index: URL
        let dir: URL
        let info: Info?
        let live: Bool
    }

    /// The page to show: the downloaded one when it's usable and newer than the built-in one, otherwise the built-in one.
    static func pick() -> Choice? {
        let bundled = info(in: bundledDir)
        if !disabled, let live = info(in: liveDir), live.minNative <= NATIVE_API, live.sha != badSha,
           live.time > (bundled?.time ?? 0),
           FileManager.default.fileExists(atPath: liveDir.appendingPathComponent("index.html").path) {
            return Choice(index: liveDir.appendingPathComponent("index.html"), dir: liveDir, info: live, live: true)
        }
        guard let dir = bundledDir else { return nil }
        return Choice(index: dir.appendingPathComponent("index.html"), dir: dir, info: bundled, live: false)
    }

    private static var checking = false
    private static let session = URLSession(configuration: .ephemeral)

    /// Looks for a newer page online. Calls done(true) on the main thread once one is downloaded and checked.
    static func check(done: @escaping (Bool) -> Void) {
        guard !disabled, !checking else { return }
        checking = true
        Task {
            let ok = await download()
            await MainActor.run {
                checking = false
                done(ok)
            }
        }
    }

    private static func fetch(_ path: String, query: String) async throws -> Data {
        guard var parts = URLComponents(url: site.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        parts.query = query   // a fresh query each time gets past GitHub's 10-minute cache
        guard let url = parts.url else { throw URLError(.badURL) }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }

    private static func download() async -> Bool {
        do {
            let manifest = try await fetch("version.json", query: "t=\(Int(Date().timeIntervalSince1970))")
            let remote = try JSONDecoder().decode(Info.self, from: manifest)
            let newest = max(info(in: bundledDir)?.time ?? 0, info(in: liveDir)?.time ?? 0)
            guard remote.time > newest, remote.minNative <= NATIVE_API, remote.sha != badSha,
                  remote.files.contains(where: { $0.path == "index.html" }) else { return false }

            let fm = FileManager.default
            let next = root.appendingPathComponent("next", isDirectory: true)
            try? fm.removeItem(at: next)
            try fm.createDirectory(at: next, withIntermediateDirectories: true)
            for file in remote.files {
                guard !file.path.contains(".."), !file.path.hasPrefix("/") else { return false }
                let body = try await fetch(file.path, query: "v=\(remote.sha)")
                let hex = SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined()
                guard hex == file.sha256 else { return false }   // half-deployed or damaged: try again next time
                let dest = next.appendingPathComponent(file.path)
                try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try body.write(to: dest, options: .atomic)
            }
            try manifest.write(to: next.appendingPathComponent("version.json"), options: .atomic)
            try? fm.removeItem(at: liveDir)
            try fm.moveItem(at: next, to: liveDir)
            return true
        } catch {
            return false
        }
    }
}
