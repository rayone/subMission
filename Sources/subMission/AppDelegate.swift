import AppKit
import os.log
import TransmissionRPC

private let log = Logger(subsystem: "subMission", category: "ui")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?
    private let appService: AppService

    override init() {
        self.appService = AppService()
        super.init()
    }
    /// URLs queued before the session is ready (app launched by URL scheme)
    private var pendingURLs: [URL] = []
    private var appearanceObserver: AppearanceObserver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build main menu
        buildMainMenu()

        // Start watching system appearance; switches Dock icon between dark/light
        appearanceObserver = AppearanceObserver()

        // Configure service from saved settings
        let cfg = ServerConfig.load()
        appService.configure(
            host: cfg.host,
            port: cfg.port,
            path: cfg.path,
            useHTTPS: cfg.useHTTPS,
            username: cfg.username.isEmpty ? nil : cfg.username,
            password: cfg.password.isEmpty ? nil : cfg.password
        )

        // Launch main window
        let wc = MainWindowController(appService: appService)
        mainWindowController = wc
        wc.showWindow(nil)

        // Install details panel
        let details = TorrentDetailsController(appService: appService)
        wc.installDetailsController(details)

        // Start polling; drain any queued URLs after first successful session fetch
        appService.startPolling(interval: .seconds(cfg.pollInterval))
        waitForSessionThenDrainPending()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - URL / file handling (magnet links, .torrent drag from browser)

    func application(_ application: NSApplication, open urls: [URL]) {
        if appService.session != nil {
            // Session ready — handle immediately
            handleURLs(urls)
        } else {
            // App still launching — queue for after session is ready
            pendingURLs.append(contentsOf: urls)
        }
    }

    /// Poll until session is available, then drain pending URLs.
    private func waitForSessionThenDrainPending() {
        Task { @MainActor in
            // Wait up to 10 seconds for the first session fetch
            for _ in 0..<20 {
                if appService.session != nil { break }
                try? await Task.sleep(for: .milliseconds(500))
            }
            let pending = pendingURLs
            pendingURLs.removeAll()
            handleURLs(pending)
        }
    }

    private func handleURLs(_ urls: [URL]) {
        for url in urls {
            if url.scheme?.lowercased() == "magnet" {
                addMagnet(url.absoluteString)
            } else if url.isFileURL && url.pathExtension.lowercased() == "torrent" {
                addTorrentFile(url)
            }
        }
    }

    private func addMagnet(_ magnetURL: String) {
        guard let wc = mainWindowController else { return }
        let tlc = wc.torrentListController
        guard let window = wc.window else { return }
        let sheet = AddLinkSheet(appService: appService)
        sheet.prefill = magnetURL
        Task { @MainActor in
            let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
            sheetWindow.styleMask = [.titled, .closable]
            let result: (url: String, dir: String, start: Bool)? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let r = result, !r.url.isEmpty else { return }
            var req = AddTorrentRequest(filename: r.url)
            req.downloadDir = r.dir
            req.paused = !r.start
            _ = try? await appService.rpcSession?.addTorrent(req)
            LayoutState.saveLastUsedDir(r.dir)
            await appService.refresh()
            _ = tlc  // keep reference alive
        }
    }

    private func addTorrentFile(_ url: URL) {
        guard let wc = mainWindowController, let window = wc.window else { return }
        guard let sheet = try? AddTorrentSheet(torrentURL: url, appService: appService) else { return }
        Task { @MainActor in
            let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
            sheetWindow.styleMask = [.titled, .closable, .resizable]
            sheetWindow.setContentSize(sheet.preferredContentSize)
            let result: AddTorrentResult? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let r = result else { return }
            var req = AddTorrentRequest(metainfo: r.torrentData.base64EncodedString())
            req.downloadDir = r.downloadDir
            req.paused = r.paused
            req.bandwidthPriority = r.bandwidthPriority
            req.filesWanted = r.filesWanted
            req.filesUnwanted = r.filesUnwanted
            req.priorityHigh = r.priorityHigh
            req.priorityLow = r.priorityLow
            _ = try? await appService.rpcSession?.addTorrent(req)
            LayoutState.saveLastUsedDir(r.downloadDir)
            await appService.refresh()
        }
    }

    // MARK: - Menu

    private func buildMainMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: S.App.about, action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: S.App.preferences, action: #selector(openPreferences), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: S.App.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // Edit menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: S.Edit.menu)
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: S.Edit.undo,       action: #selector(UndoManager.undo),              keyEquivalent: "z")
        editMenu.addItem(withTitle: S.Edit.redo,       action: #selector(UndoManager.redo),              keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: S.Edit.cut,        action: #selector(NSText.cut(_:)),                keyEquivalent: "x")
        editMenu.addItem(withTitle: S.Edit.copy,       action: #selector(NSText.copy(_:)),               keyEquivalent: "c")
        editMenu.addItem(withTitle: S.Edit.paste,      action: #selector(NSText.paste(_:)),              keyEquivalent: "v")
        editMenu.addItem(withTitle: S.Edit.selectAll,  action: #selector(NSText.selectAll(_:)),          keyEquivalent: "a")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: S.Edit.find,       action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")

        // Torrent menu
        let torrentMenuItem = NSMenuItem()
        mainMenu.addItem(torrentMenuItem)
        let torrentMenu = NSMenu(title: S.TorrentMenu.menu)
        torrentMenuItem.submenu = torrentMenu
        torrentMenu.addItem(withTitle: S.TorrentMenu.addFile, action: #selector(addFile), keyEquivalent: "o")
        torrentMenu.addItem(withTitle: S.TorrentMenu.addURL,  action: #selector(addLink), keyEquivalent: "u")
        torrentMenu.addItem(.separator())
        torrentMenu.addItem(withTitle: S.TorrentMenu.start, action: #selector(startSelected), keyEquivalent: "")
        torrentMenu.addItem(withTitle: S.TorrentMenu.stop,  action: #selector(stopSelected), keyEquivalent: "")
        let removeItem = NSMenuItem(title: S.ContextMenu.remove, action: #selector(removeSelected), keyEquivalent: "\u{8}") // ⌘⌫
        removeItem.keyEquivalentModifierMask = .command
        torrentMenu.addItem(removeItem)
        let removeData = NSMenuItem(title: S.ContextMenu.removeWithData, action: #selector(removeWithDataSelected), keyEquivalent: "\u{8}") // ⇧⌫
        removeData.keyEquivalentModifierMask = .shift
        torrentMenu.addItem(removeData)

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: S.WindowMenu.menu)
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: S.WindowMenu.minimize, action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: S.WindowMenu.zoom,     action: #selector(NSWindow.zoom(_:)),        keyEquivalent: "")
        NSApp.windowsMenu = windowMenu
    }

    @objc private func openPreferences() {
        SettingsWindowController.showWindow(nil, appService: appService)
    }

    @objc private func showAbout() {
        AboutWindowController.show()
    }

    @objc private func addFile() {
        mainWindowController?.torrentListController.addFile(nil)
    }

    @objc private func addLink() {
        mainWindowController?.torrentListController.addLink(nil)
    }

    @objc private func startSelected() {
        mainWindowController?.torrentListController.startSelected(nil)
    }

    @objc private func stopSelected() {
        mainWindowController?.torrentListController.stopSelected(nil)
    }

    @objc private func removeSelected() {
        mainWindowController?.torrentListController.removeSelected(nil)
    }

    @objc private func removeWithDataSelected() {
        mainWindowController?.torrentListController.removeWithDataSelected(nil)
    }
}
