import AppKit
import TransmissionRPC

// MARK: - Toolbar item identifiers

extension NSToolbarItem.Identifier {
    static let add        = NSToolbarItem.Identifier("add")
    static let controls   = NSToolbarItem.Identifier("controls")   // start/stop/remove group
    static let altSpeed   = NSToolbarItem.Identifier("altSpeed")
    static let speedGraph = NSToolbarItem.Identifier("speedGraph")
    static let panels     = NSToolbarItem.Identifier("panels")
    static let settings   = NSToolbarItem.Identifier("settings")
    static let start      = NSToolbarItem.Identifier("start")
    static let stop       = NSToolbarItem.Identifier("stop")
    static let remove     = NSToolbarItem.Identifier("remove")
}

// MARK: - MainWindowController

final class MainWindowController: NSWindowController, NSToolbarDelegate, NSWindowDelegate {

    private(set) var torrentListController: TorrentListController
    private      var detailsController: TorrentDetailsController?
    private      var settingsPaneController: SettingsPaneController
    private      let appService: AppService

    // Split views
    private var hSplit: NSSplitView!   // sidebar | main
    private var vSplit: NSSplitView!   // torrent list | details

    // Toolbar controls
    private var startButton:    NSButton?
    private var stopButton:     NSButton?
    private var removeButton:   NSButton?
    private var altSpeedItem:   NSToolbarItem?
    private var speedGraphView: SpeedGraphView?
    private var panelsControl:  NSSegmentedControl?
    private var footerView:     StatusFooterView?
    private weak var mainToolbar: NSToolbar?

    private var observerToken: ObserverToken?

    // MARK: - Init

    init(appService: AppService) {
        self.appService = appService
        self.torrentListController = TorrentListController(appService: appService)
        self.settingsPaneController = SettingsPaneController(appService: appService)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "subMission"
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 640, height: 400)
        window.center()
        super.init(window: window)
        window.delegate = self
        buildUI()
        installToolbar()
        subscribeToService()
        NotificationCenter.default.addObserver(self, selector: #selector(toggleDetailsPanel),
                                               name: .toggleDetailsPanel, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        observerToken?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Build UI

    private func buildUI() {
        guard let window else { return }

        // --- Vertical split: torrent list (top) | details (bottom) ---
        vSplit = NSSplitView()
        vSplit.isVertical = false
        vSplit.dividerStyle = .thin
        vSplit.translatesAutoresizingMaskIntoConstraints = false

        let listHost = containerView(for: torrentListController)
        vSplit.addArrangedSubview(listHost)

        // --- Horizontal split: main (left) | settings (right) ---
        hSplit = NSSplitView()
        hSplit.isVertical = true
        hSplit.dividerStyle = .thin
        hSplit.translatesAutoresizingMaskIntoConstraints = false

        hSplit.addArrangedSubview(vSplit)

        // Settings pane — right side, hidden by default
        let settingsHost = containerView(for: settingsPaneController)
        settingsHost.isHidden = true
        hSplit.addArrangedSubview(settingsHost)
        hSplit.setHoldingPriority(.defaultLow + 1, forSubviewAt: 1)

        // --- Footer ---
        let footer = StatusFooterView(appService: appService)
        footer.translatesAutoresizingMaskIntoConstraints = false
        footerView = footer

        // --- Content view: hSplit fills all but the footer strip ---
        let content = NSView()
        content.addSubview(hSplit)
        content.addSubview(footer)
        NSLayoutConstraint.activate([
            hSplit.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            hSplit.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            hSplit.topAnchor.constraint(equalTo: content.topAnchor),
            hSplit.bottomAnchor.constraint(equalTo: footer.topAnchor),

            footer.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        window.contentView = content
    }

    private func containerView(for vc: NSViewController) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let child = vc.view
        child.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            child.topAnchor.constraint(equalTo: v.topAnchor),
            child.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        return v
    }

    // MARK: - Toolbar

    private func installToolbar() {
        let toolbar = NSToolbar(identifier: "MainToolbar4")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
        mainToolbar = toolbar
        if #available(macOS 11, *) { window?.toolbarStyle = .unified }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.add, .flexibleSpace, .speedGraph, .flexibleSpace, .panels, .altSpeed, .settings]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.add, .controls, .flexibleSpace, .speedGraph, .flexibleSpace, .panels, .altSpeed, .settings]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch id {
        case .add:        return makeAddItem()
        case .controls:   return makeControlsGroup()
        case .start:      return makeStartItem()
        case .stop:       return makeStopItem()
        case .remove:     return makeRemoveItem()
        case .altSpeed:   return makeAltSpeedItem()
        case .speedGraph: return makeSpeedGraphItem()
        case .panels:     return makePanelsItem()
        case .settings:   return makeSettingsItem()
        default:          return nil
        }
    }

    // MARK: - Toolbar item factories

    private func makeAddItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .add)
        item.label = S.Toolbar.add; item.toolTip = S.Toolbar.addTip
        item.image = sym("plus")
        item.target = self; item.action = #selector(showAddMenu(_:))
        item.isBordered = true
        return item
    }

    private func makeControlsGroup() -> NSToolbarItemGroup {
        let startItem = NSToolbarItem(itemIdentifier: .start)
        startItem.label = S.Toolbar.start; startItem.toolTip = S.Toolbar.startTip
        startItem.image = sym("play.fill")
        startItem.target = torrentListController
        startItem.action = #selector(TorrentListController.startSelected(_:))
        startItem.isBordered = true

        let stopItem = NSToolbarItem(itemIdentifier: .stop)
        stopItem.label = S.Toolbar.stop; stopItem.toolTip = S.Toolbar.stopTip
        stopItem.image = sym("stop.fill")
        stopItem.target = torrentListController
        stopItem.action = #selector(TorrentListController.stopSelected(_:))
        stopItem.isBordered = true

        let removeItem = NSToolbarItem(itemIdentifier: .remove)
        removeItem.label = S.Toolbar.remove; removeItem.toolTip = S.Toolbar.removeTip
        removeItem.image = sym("trash")
        removeItem.target = torrentListController
        removeItem.action = #selector(TorrentListController.removeSelected(_:))
        removeItem.isBordered = true

        let group = NSToolbarItemGroup(itemIdentifier: .controls)
        group.subitems = [startItem, stopItem, removeItem]
        group.label = S.Toolbar.controls
        // Store button refs via the group's view (NSSegmentedControl) — we'll hide the whole group
        return group
    }

    // keep individual factories for toolbarAllowedItemIdentifiers resolution
    private func makeStartItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .start)
        item.image = sym("play.fill"); item.isBordered = true
        item.target = torrentListController
        item.action = #selector(TorrentListController.startSelected(_:))
        return item
    }
    private func makeStopItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .stop)
        item.image = sym("stop.fill"); item.isBordered = true
        item.target = torrentListController
        item.action = #selector(TorrentListController.stopSelected(_:))
        return item
    }
    private func makeRemoveItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .remove)
        item.image = sym("trash"); item.isBordered = true
        item.target = torrentListController
        item.action = #selector(TorrentListController.removeSelected(_:))
        return item
    }

    private func makeAltSpeedItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .altSpeed)
        item.label = S.Toolbar.altSpeed
        item.toolTip = S.Toolbar.altSpeedTip
        item.image = sym("tortoise.fill")
        item.isBordered = true
        item.target = self
        item.action = #selector(toggleAltSpeed(_:))
        altSpeedItem = item
        return item
    }

    private func makeSpeedGraphItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .speedGraph)
        item.label = S.Toolbar.speed
        let graph = SpeedGraphView(frame: NSRect(x: 0, y: 0, width: 120, height: 24), appService: appService)
        graph.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            graph.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            graph.widthAnchor.constraint(lessThanOrEqualToConstant: 2000),
            graph.heightAnchor.constraint(equalToConstant: 24),
        ])
        speedGraphView = graph
        item.view = graph
        return item
    }

    private func makePanelsItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .panels)
        item.label = S.Toolbar.panels
        let seg = NSSegmentedControl(
            images: [sym("rectangle.bottomhalf.inset.filled")!],
            trackingMode: .selectAny,
            target: self, action: #selector(panelsChanged(_:))
        )
        seg.setSelected(true, forSegment: 0)
        seg.setToolTip(S.Toolbar.detailsTip, forSegment: 0)
        panelsControl = seg
        item.view = seg
        return item
    }

    private func makeSettingsItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .settings)
        item.label = S.Toolbar.settings; item.toolTip = S.Toolbar.settingsTip
        let btn = NSButton(image: sym("gear")!, target: self, action: #selector(toggleSettings(_:)))
        btn.bezelStyle = .toolbar
        btn.setButtonType(.toggle)
        item.view = btn
        return item
    }

    private func sym(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    // MARK: - Toolbar actions

    @objc private func showAddMenu(_ sender: Any?) {
        let menu = NSMenu()
        menu.addItem(withTitle: S.TorrentMenu.addFile, action: #selector(TorrentListController.addFile(_:)), keyEquivalent: "")
        menu.addItem(withTitle: S.TorrentMenu.addURL,    action: #selector(TorrentListController.addLink(_:)), keyEquivalent: "")
        menu.items.forEach { $0.target = torrentListController }
        // Show below the toolbar item's view if possible, otherwise at mouse location
        if let btn = sender as? NSButton {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: btn.bounds.maxY), in: btn)
        } else {
            let pt = NSEvent.mouseLocation
            menu.popUp(positioning: nil, at: window?.convertPoint(fromScreen: pt) ?? .zero, in: window?.contentView)
        }
    }

    @objc private func toggleAltSpeed(_ sender: Any?) {
        guard let rpcSession = appService.rpcSession else {
            return
        }
        let current = appService.session?.altSpeedEnabled ?? false
        let newValue = !current
        // Optimistic UI
        updateAltSpeedIcon(enabled: newValue)
        Task {
            var patch = SessionPatch()
            patch.altSpeedEnabled = newValue
            do {
                try await rpcSession.setSession(patch)
                await appService.refresh()
            } catch {
                self.updateAltSpeedIcon(enabled: current)
            }
        }
    }

    private func updateAltSpeedIcon(enabled: Bool) {
        if enabled {
            // Blue-tinted filled tortoise when alt speed is active
            let img = sym("tortoise.fill")!
            altSpeedItem?.image = img.withSymbolConfiguration(.init(paletteColors: [.white, Theme.blue])) ?? img
            altSpeedItem?.label = S.Toolbar.altSpeedOn
        } else {
            altSpeedItem?.image = sym("tortoise")
            altSpeedItem?.label = S.Toolbar.altSpeed
        }
    }

    @objc private func panelsChanged(_ sender: NSSegmentedControl) {
        setDetailsVisible(sender.isSelected(forSegment: 0))
    }

    @objc func toggleDetailsPanel() {
        guard let seg = panelsControl else { return }
        let newState = !seg.isSelected(forSegment: 0)
        seg.setSelected(newState, forSegment: 0)
        setDetailsVisible(newState)
    }

    @objc private func toggleSettings(_ sender: NSButton) {
        let visible = sender.state == .on
        setSettingsPaneVisible(visible)
    }

    private func setSettingsPaneVisible(_ visible: Bool) {
        guard hSplit.arrangedSubviews.count > 1 else { return }
        let pane = hSplit.arrangedSubviews[1]
        pane.isHidden = !visible
        if visible { settingsPaneController.reload() }
    }

    @objc private func openSettings(_ sender: Any?) {
        SettingsWindowController.showWindow(nil, appService: appService)
    }

    private func setDetailsVisible(_ visible: Bool) {
        if vSplit.arrangedSubviews.count > 1 {
            vSplit.arrangedSubviews[1].isHidden = !visible
        }
        if visible { autoPositionDetailsDivider(force: true) }
    }

    // MARK: - Service observer

    private func subscribeToService() {
        observerToken = appService.addObserver { [weak self] event in
            switch event {
            case .selectionChanged: self?.updateToolbarState()
            case .torrentsUpdated:  self?.autoPositionDetailsDivider()   // no-op if count unchanged
            case .sessionUpdated:
                self?.syncAltSpeedButton()
                if let pane = self?.hSplit.arrangedSubviews.indices.contains(1) == true
                    ? self?.hSplit.arrangedSubviews[1] : nil, !pane.isHidden,
                   self?.settingsPaneController.isEditing == false {
                    self?.settingsPaneController.reload()
                }
            default: break
            }
        }
    }

    private var lastAutoPositionRowCount = -1

    // MARK: - Auto-position details divider

    /// Positions the divider so the list fits its content exactly.
    /// Only moves the divider when row count changes, or when `force` is true.
    func autoPositionDetailsDivider(force: Bool = false) {
        guard vSplit.arrangedSubviews.count > 1,
              !vSplit.arrangedSubviews[1].isHidden else { return }
        let rowCount = torrentListController.tableRowCount
        guard force || rowCount != lastAutoPositionRowCount else { return }
        lastAutoPositionRowCount = rowCount

        let available = vSplit.bounds.height
        guard available > 0 else { return }

        let minDetails: CGFloat = 120
        let preferred = torrentListController.preferredListHeight
        let pos = max(0, min(preferred, available - minDetails))
        vSplit.setPosition(pos, ofDividerAt: 0)
    }

    private func updateToolbarState() {
        let has = !appService.selectedIDs.isEmpty
        guard let toolbar = mainToolbar else { return }
        let hasControls = toolbar.items.contains { $0.itemIdentifier == .controls }
        if has && !hasControls {
            // Insert controls group after add (index 1)
            toolbar.insertItem(withItemIdentifier: .controls, at: 1)
        } else if !has && hasControls {
            if let idx = toolbar.items.firstIndex(where: { $0.itemIdentifier == .controls }) {
                toolbar.removeItem(at: idx)
            }
        }
    }

    private func syncAltSpeedButton() {
        let enabled = appService.session?.altSpeedEnabled ?? false
        updateAltSpeedIcon(enabled: enabled)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        updateToolbarState()
        let layout = LayoutState.load()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let win = self.window {
                var frame = win.frame
                frame.size = NSSize(width: layout.windowWidth, height: layout.windowHeight)
                win.setFrame(frame, display: false)
                win.center()
            }
            self.autoPositionDetailsDivider(force: true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        var layout = LayoutState.load()
        if let win = window {
            layout.windowWidth  = Double(win.frame.width)
            layout.windowHeight = Double(win.frame.height)
        }
        layout.save()
        torrentListController.saveLayout()
    }

    // MARK: - Install details panel (called from Phase 6)

    func installDetailsController(_ dc: TorrentDetailsController) {
        detailsController = dc
        let host = containerView(for: dc)
        NSLayoutConstraint.activate([
            host.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])
        vSplit.addArrangedSubview(host)
        // List pane holds its size; details grows/shrinks on window resize
        vSplit.setHoldingPriority(.defaultLow + 1, forSubviewAt: 0)
        host.isHidden = false
        panelsControl?.setSelected(true, forSegment: 0)
        DispatchQueue.main.async { self.autoPositionDetailsDivider(force: true) }
    }
}

// MARK: - Toolbar validation

extension MainWindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case .start, .stop, .remove:
            return !appService.selectedIDs.isEmpty
        default:
            return true
        }
    }
}
