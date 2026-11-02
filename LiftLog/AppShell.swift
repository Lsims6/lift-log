import UIKit

/// The app's frame: Apple's own tab bar (Liquid Glass on iOS 26) with Workout and Food, around the one web page.
/// The page is a single WKWebView; each tab is an empty screen that the page moves into when its tab is picked,
/// and the page shows that section. When the page changes section itself (or is on the first-run setup, which
/// has no tabs), it tells the shell with a "chrome" message so the tab bar follows along.
final class AppShell: UITabBarController, UITabBarControllerDelegate {
    let web = WebViewController()
    private var reselect = false

    final class TabPage: UIViewController {
        let section: String
        init(section: String, title: String, symbol: String) {
            self.section = section
            super.init(nibName: nil, bundle: nil)
            tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), tag: 0)
        }
        required init?(coder: NSCoder) { fatalError("not used") }
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .liftLogBackground
        }
    }

    private lazy var pages = [
        TabPage(section: "workout", title: "Workout", symbol: "dumbbell.fill"),
        TabPage(section: "food", title: "Food", symbol: "fork.knife"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .liftLogBackground
        viewControllers = pages
        delegate = self
        tabBar.tintColor = .liftLogAccent
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior = .onScrollDown   // the glass bar shrinks while scrolling down the page
        }
        web.shell = self
        let start = UserDefaults.standard.string(forKey: "shell.section") == "food" ? 1 : 0
        selectedIndex = start
        host(in: pages[start])
    }

    /// Moves the page into the given tab's screen.
    private func host(in page: TabPage) {
        guard web.parent !== page else { return }
        if web.parent != nil {
            web.willMove(toParent: nil)
            web.view.removeFromSuperview()
            web.removeFromParent()
        }
        page.loadViewIfNeeded()
        page.addChild(web)
        web.view.frame = page.view.bounds
        web.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        page.view.addSubview(web.view)
        web.didMove(toParent: page)
        page.setContentScrollView(web.scrollView, for: .bottom)
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        reselect = viewController === selectedViewController
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let page = viewController as? TabPage else { return }
        host(in: page)
        UserDefaults.standard.set(page.section, forKey: "shell.section")
        web.showSection(page.section, again: reselect)
        reselect = false
    }

    /// The page says which section it's in and whether the tab bar should show (it hides on first-run setup).
    func pageChanged(section: String, showTabs: Bool) {
        if let i = pages.firstIndex(where: { $0.section == section }), i != selectedIndex {
            selectedIndex = i
            host(in: pages[i])
            UserDefaults.standard.set(section, forKey: "shell.section")
        }
        if tabBar.isHidden == showTabs {
            tabBar.isHidden = !showTabs
        }
    }
}

extension UIColor {
    /// The page's --accent token in light and dark mode.
    static let liftLogAccent = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5B / 255, green: 0x8C / 255, blue: 0xFF / 255, alpha: 1)
            : UIColor(red: 0x1F / 255, green: 0x56 / 255, blue: 0xC9 / 255, alpha: 1)
    }
}
