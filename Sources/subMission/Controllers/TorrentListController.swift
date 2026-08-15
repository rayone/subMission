import AppKit
import TransmissionRPC

// MARK: - Column identifiers

private extension NSUserInterfaceItemIdentifier {
    static let name       = NSUserInterfaceItemIdentifier("name")
    static let status     = NSUserInterfaceItemIdentifier("status")
    static let progress   = NSUserInterfaceItemIdentifier("progress")
    static let size       = NSUserInterfaceItemIdentifier("size")
    static let downloaded = NSUserInterfaceItemIdentifier("downloaded")
    static let uploaded   = NSUserInterfaceItemIdentifier("uploaded")
    static let ratio      = NSUserInterfaceItemIdentifier("ratio")
    static let dlSpeed    = NSUserInterfaceItemIdentifier("dlSpeed")
    static let ulSpeed    = NSUserInterfaceItemIdentifier("ulSpeed")
    static let eta        = NSUserInterfaceItemIdentifier("eta")
    static let seeds      = NSUserInterfaceItemIdentifier("seeds")
    static let peers      = NSUserInterfaceItemIdentifier("peers")
    static let queue      = NSUserInterfaceItemIdentifier("queue")
    static let location   = NSUserInterfaceItemIdentifier("location")
}

private enum SortKey: String {
    case name, status, progress, size, downloaded, uploaded, ratio, dlSpeed, ulSpeed, eta, seeds, peers, queue, location
}

// MARK: - Row item (torrent or group header)

enum RowItem {
    case groupHeader(String)
    case torrent(Torrent)
}

// MARK: - TorrentListController

final class TorrentListController: NSViewController {

    private var tableView: NSTableView!
    private let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Height to show all rows plus 5 blank rows of margin below the last torrent.
    var preferredListHeight: CGFloat {
        guard isViewLoaded else { return 300 }
        let headerH = tableView.headerView?.frame.height ?? 0
        let n = tableView.numberOfRows
        guard n > 0 else { return headerH + tableView.rowHeight * 5 }
        let lastRowBottom = tableView.rect(ofRow: n - 1).maxY
        return headerH + lastRowBottom + tableView.rowHeight * 5
    }

    /// Number of rows currently in the table (torrents + group headers).
    var tableRowCount: Int { tableView.numberOfRows }
    private var scrollView: DragScrollView!

    private var sortKey: SortKey = .name
    private var sortAscending: Bool = true
    private var groupByKey: SortKey? = nil
    private var observerToken: ObserverToken?
    private(set) var displayedRows: [RowItem] = []
    private var suppressSelectionChange = false

    // Convenience: all torrent rows from displayedRows
    var displayedTorrents: [Torrent] {
        displayedRows.compactMap { if case .torrent(let t) = $0 { return t } else { return nil } }
    }

    // MARK: - Lifecycle

    override func loadView() {
        // Load persisted layout
        let layout = LayoutState.load()
        sortKey = SortKey(rawValue: layout.sortKey) ?? .name
        sortAscending = layout.sortAscending
        groupByKey = layout.groupByKey.flatMap { SortKey(rawValue: $0) }

        tableView = NSTableView()
        tableView.style = .inset
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.allowsColumnSelection = false
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.backgroundColor = Theme.tableBg
        tableView.rowHeight = 22
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        tableView.menu = buildContextMenu()

        buildColumns(layout: layout)
        installHeaderMenu()

        let dragSV = DragScrollView()
        dragSV.dragDelegate = self
        dragSV.documentView = tableView
        dragSV.hasVerticalScroller = true
        dragSV.hasHorizontalScroller = false
        dragSV.autohidesScrollers = true
        dragSV.borderType = .noBorder
        dragSV.backgroundColor = Theme.tableBg
        dragSV.drawsBackground = true

        // Register for .torrent file drag-and-drop
        dragSV.registerForDraggedTypes([.fileURL])

        scrollView = dragSV
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToService()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        tableView.sizeToFit()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        saveLayout()
    }

    deinit { observerToken?.cancel() }

    // MARK: - Layout persistence

    func saveLayout() {
        var layout = LayoutState()
        layout.sortKey = sortKey.rawValue
        layout.sortAscending = sortAscending
        layout.groupByKey = groupByKey?.rawValue
        layout.columnWidths = Dictionary(uniqueKeysWithValues:
            tableView.tableColumns.map { ($0.identifier.rawValue, Double($0.width)) })
        layout.hiddenColumns = tableView.tableColumns
            .filter { $0.isHidden }
            .map { $0.identifier.rawValue }
        layout.columnOrder = tableView.tableColumns.map { $0.identifier.rawValue }
        layout.save()
    }

    // MARK: - Columns

    private func buildColumns(layout: LayoutState) {
        let defs: [(NSUserInterfaceItemIdentifier, String, CGFloat, CGFloat)] = [
            (.name,       S.Column.name,       260, 120),
            (.status,     S.Column.status,     110,  70),
            (.progress,   S.Column.progress,   120,  80),
            (.size,       S.Column.size,         80,  60),
            (.downloaded, S.Column.downloaded,   90,  60),
            (.uploaded,   S.Column.uploaded,     90,  60),
            (.ratio,      S.Column.ratio,        60,  50),
            (.dlSpeed,    S.Column.dlSpeed,      80,  60),
            (.ulSpeed,    S.Column.ulSpeed,      80,  60),
            (.eta,        S.Column.eta,          70,  50),
            (.seeds,      S.Column.seeds,        60,  40),
            (.peers,      S.Column.peers,        60,  40),
            (.queue,      S.Column.queue,        55,  40),
            (.location,   S.Column.location,    160,  80),
        ]
        // Build a map for ordered insertion
        var colMap: [String: NSTableColumn] = [:]
        for (id, title, w, minW) in defs {
            let tc = NSTableColumn(identifier: id)
            tc.title = title
            tc.width = layout.columnWidths[id.rawValue].map { CGFloat($0) } ?? w
            tc.minWidth = minW
            tc.resizingMask = [.userResizingMask, .autoresizingMask]
            colMap[id.rawValue] = tc
        }
        // Insert in saved order if available, otherwise default order
        let orderedKeys = layout.columnOrder.isEmpty
            ? defs.map { $0.0.rawValue }
            : layout.columnOrder
        for key in orderedKeys {
            if let col = colMap[key] { tableView.addTableColumn(col) }
        }
        // Any columns not in saved order (newly added columns)
        for (id, _, _, _) in defs where !orderedKeys.contains(id.rawValue) {
            if let col = colMap[id.rawValue] { tableView.addTableColumn(col) }
        }
        // Apply visibility
        let defaultHidden = Set(["downloaded", "uploaded", "location"])
        for col in tableView.tableColumns {
            let key = col.identifier.rawValue
            if layout.columnOrder.isEmpty {
                col.isHidden = defaultHidden.contains(key)
            } else {
                col.isHidden = layout.hiddenColumns.contains(key)
            }
        }
    }

    // MARK: - Header right-click menu (column visibility + group-by)

    private func installHeaderMenu() {
        let menu = NSMenu()
        menu.delegate = self
        tableView.headerView?.menu = menu
    }

    // MARK: - Context menu

    private func buildContextMenu() -> NSMenu {
        let m = NSMenu()
        m.delegate = self
        m.autoenablesItems = false
        m.addItem(NSMenuItem(title: S.ContextMenu.resume,          action: #selector(startSelected),             keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.resumeNow,       action: #selector(forceStartSelected),        keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.pause,           action: #selector(stopSelected),              keyEquivalent: ""))
        m.addItem(.separator())
        // Priority submenu
        let prioSub = NSMenu()
        prioSub.autoenablesItems = false
        let highItem = NSMenuItem(title: S.ContextMenu.priorityHigh, action: #selector(setPriorityHigh), keyEquivalent: "")
        highItem.target = self; highItem.tag = 1
        let normalItem = NSMenuItem(title: S.ContextMenu.priorityNormal, action: #selector(setPriorityNormal), keyEquivalent: "")
        normalItem.target = self; normalItem.tag = 0
        let lowItem = NSMenuItem(title: S.ContextMenu.priorityLow, action: #selector(setPriorityLow), keyEquivalent: "")
        lowItem.target = self; lowItem.tag = -1
        prioSub.addItem(highItem)
        prioSub.addItem(normalItem)
        prioSub.addItem(lowItem)
        let prioItem = NSMenuItem(title: S.ContextMenu.priority, action: nil, keyEquivalent: "")
        prioItem.submenu = prioSub
        m.addItem(prioItem)
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: S.ContextMenu.moveTop,         action: #selector(queueTop),                  keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.moveUp,          action: #selector(queueUp),                   keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.moveDown,        action: #selector(queueDown),                 keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.moveBottom,      action: #selector(queueBottom),               keyEquivalent: ""))
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: S.ContextMenu.remove,          action: #selector(removeSelected),            keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.removeWithData,  action: #selector(removeWithDataSelected),    keyEquivalent: ""))
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: S.ContextMenu.verify,          action: #selector(verifySelected),            keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.setLocation,     action: #selector(setLocationSelected),       keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.rename,          action: #selector(renameSelected),            keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.reannounce,      action: #selector(reannounceSelected),        keyEquivalent: ""))
        m.addItem(.separator())
        m.addItem(NSMenuItem(title: S.ContextMenu.selectAll,       action: #selector(NSResponder.selectAll(_:)), keyEquivalent: ""))
        m.addItem(NSMenuItem(title: S.ContextMenu.deselectAll,     action: #selector(deselectAll),               keyEquivalent: ""))
        // Set target on action items only (skip submenu parent which has action: nil)
        for item in m.items where item.action != nil {
            item.target = self
        }
        return m
    }

    // MARK: - Observer

    private func subscribeToService() {
        observerToken = appService.addObserver { [weak self] event in
            switch event {
            case .torrentsUpdated:   self?.refreshDisplay()
            case .selectionChanged:  self?.syncSelectionFromService()
            default: break
            }
        }
        refreshDisplay()
    }

    // MARK: - Display refresh

    private func refreshDisplay() {
        // AppService state should be read on MainActor
        let currentTorrents = appService.filteredTorrents
        let currentGroupBy = groupByKey
        let currentOldTorrents = displayedTorrents

        Task.detached {
            let sorted = await self.sortedTorrents(currentTorrents)
            let newRows = await self.buildRows(from: sorted, groupBy: currentGroupBy)
            let newTorrents = newRows.compactMap { if case .torrent(let t) = $0 { return t } else { return nil } }
            
            var changeset: TableChangeset? = nil
            if currentGroupBy == nil {
                changeset = computeChangeset(old: currentOldTorrents, new: newTorrents)
            }
            let computedChangeset = changeset

            await MainActor.run {
                self.suppressSelectionChange = true
                defer {
                    self.suppressSelectionChange = false
                    self.syncSelectionFromService()
                }

                self.displayedRows = newRows

                // Always full reload when grouping is active
                guard let changeset = computedChangeset else {
                    self.tableView.reloadData()
                    return
                }

                // Full reload when rows are added or removed — avoids index mismatch
                // between torrent-array space and table row space (group headers shift indices)
                if !changeset.deletions.isEmpty || !changeset.insertions.isEmpty {
                    self.tableView.applyChangeset(changeset, withAnimation: .effectFade)
                    return
                }

                // Pure content update: reload only visible rows
                if !changeset.reloads.isEmpty || !changeset.moves.isEmpty {
                    let visible = self.tableView.rows(in: self.tableView.visibleRect)
                    if visible.length > 0 {
                        self.tableView.reloadData(
                            forRowIndexes: IndexSet(integersIn: visible.location ..< (visible.location + visible.length)),
                            columnIndexes: IndexSet(integersIn: 0 ..< self.tableView.numberOfColumns)
                        )
                    }
                }
            }
        }
    }

    private func buildRows(from torrents: [Torrent], groupBy: SortKey?) -> [RowItem] {
        guard let key = groupBy else {
            return torrents.map { .torrent($0) }
        }
        // Group torrents by the group key value
        var groups: [(String, [Torrent])] = []
        var seen: [String: Int] = [:]
        for t in torrents {
            let gv = groupValue(torrent: t, key: key)
            if let idx = seen[gv] {
                groups[idx].1.append(t)
            } else {
                seen[gv] = groups.count
                groups.append((gv, [t]))
            }
        }
        var rows: [RowItem] = []
        for (header, items) in groups {
            rows.append(.groupHeader(header))
            rows.append(contentsOf: items.map { .torrent($0) })
        }
        return rows
    }

    private func groupValue(torrent: Torrent, key: SortKey) -> String {
        switch key {
        case .status:   return Formatters.formatStatusString(torrent)
        case .location: return torrent.downloadDir
        default:        return ""
        }
    }

    // MARK: - Sort

    private func sortedTorrents(_ list: [Torrent]) -> [Torrent] {
        list.sorted { a, b in
            let (lhs, rhs) = sortAscending ? (a, b) : (b, a)
            switch sortKey {
            case .name:       return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .status:     let l = Formatters.formatStatusString(lhs), r = Formatters.formatStatusString(rhs)
                              return l.localizedCaseInsensitiveCompare(r) == .orderedAscending
            case .progress:   return lhs.percentDone   < rhs.percentDone
            case .size:       return lhs.totalSize      < rhs.totalSize
            case .downloaded: return lhs.downloadedEver < rhs.downloadedEver
            case .uploaded:   return lhs.uploadedEver   < rhs.uploadedEver
            case .ratio:      return lhs.uploadRatio    < rhs.uploadRatio
            case .dlSpeed:    return lhs.rateDownload   < rhs.rateDownload
            case .ulSpeed:    return lhs.rateUpload     < rhs.rateUpload
            case .eta:        return lhs.eta            < rhs.eta
            case .seeds:      return lhs.peersSendingToUs < rhs.peersSendingToUs
            case .peers:      return lhs.peersConnected < rhs.peersConnected
            case .queue:      return lhs.queuePosition  < rhs.queuePosition
            case .location:   return lhs.downloadDir.localizedCaseInsensitiveCompare(rhs.downloadDir) == .orderedAscending
            }
        }
    }

    // MARK: - Selection sync

    private func syncSelectionFromService() {
        let ids = appService.selectedIDs
        var indexes = IndexSet()
        for (i, row) in displayedRows.enumerated() {
            if case .torrent(let t) = row, ids.contains(t.id) { indexes.insert(i) }
        }
        tableView.selectRowIndexes(indexes, byExtendingSelection: false)
    }

    // MARK: - Key handlers

    override func keyDown(with event: NSEvent) {
        let cmd   = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)

        switch event.keyCode {
        case 51:  // ⌫ Delete/Backspace
            if shift { removeWithDataSelected(nil) }
            else     { removeSelected(nil) }
        case 117: // ⌦ Forward Delete
            removeSelected(nil)
        case 49:  // Space — toggle start/stop
            let sel = appService.selectedTorrents
            if sel.allSatisfy({ $0.status == .stopped }) { startSelected(nil) }
            else                                          { stopSelected(nil)  }
        case 36:  // ↩ Return
            if cmd && shift { forceStartSelected(nil) }
            else            { renameSelected(nil) }
        case 126: // ↑ Up Arrow
            if      cmd && shift { queueTop(nil) }
            else if cmd          { queueUp(nil)  }
            else                 { super.keyDown(with: event) }
        case 125: // ↓ Down Arrow
            if      cmd && shift { queueBottom(nil) }
            else if cmd          { queueDown(nil)   }
            else                 { super.keyDown(with: event) }
        case 37:  // L
            if cmd { setLocationSelected(nil) }
            else   { super.keyDown(with: event) }
        case 16:  // Y
            if cmd { verifySelected(nil) }
            else   { super.keyDown(with: event) }
        case 17:  // T
            if cmd { reannounceSelected(nil) }
            else   { super.keyDown(with: event) }
        case 15:  // R — refresh
            Task { await self.appService.refresh() }
        case 53:  // ⎋ Escape
            deselectAll(nil)
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Actions (toolbar + menu + keyboard)

    @objc func addFile(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "torrent")!]
        panel.allowsMultipleSelection = true
        panel.message = S.AddTorrent.openPanelMessage
        guard let window = view.window, !appService.isMutating else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let self = self else { return }
            for url in panel.urls {
                guard let sheet = try? AddTorrentSheet(torrentURL: url, appService: self.appService) else { continue }
                Task {
                    let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
                    sheetWindow.styleMask = [.titled, .closable, .resizable]
                    sheetWindow.setContentSize(sheet.preferredContentSize)
                    let result: AddTorrentResult? = await withCheckedContinuation { cont in
                        sheet.presentedContinuation = cont
                        window.beginSheet(sheetWindow)
                    }
                    guard let r = result else { return }
                    self.appService.setMutating(true)
                    var req = AddTorrentRequest(metainfo: r.torrentData.base64EncodedString())
                    req.downloadDir = r.downloadDir
                    req.paused = r.paused
                    req.bandwidthPriority = r.bandwidthPriority
                    req.filesWanted = r.filesWanted
                    req.filesUnwanted = r.filesUnwanted
                    req.priorityHigh = r.priorityHigh
                    req.priorityLow = r.priorityLow
                    _ = try? await self.appService.rpcSession?.addTorrent(req)
                    LayoutState.saveLastUsedDir(r.downloadDir)
                    await self.appService.refresh()
                    self.appService.setMutating(false)
                }
            }
        }
    }

    @objc func addLink(_ sender: Any?) {
        guard let window = view.window, !appService.isMutating else { return }
        let clip = NSPasteboard.general.string(forType: .string) ?? ""
        let prefill = (clip.hasPrefix("magnet:") || clip.hasPrefix("http")) ? clip : ""
        Task {
            let sheet = AddLinkSheet(appService: appService)
            let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
            sheetWindow.styleMask = [.titled, .closable]
            let result: (url: String, dir: String, start: Bool)? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                sheet.prefill = prefill
                window.beginSheet(sheetWindow)
            }
            guard let r = result, !r.url.isEmpty else { return }
            self.appService.setMutating(true)
            var req = AddTorrentRequest(filename: r.url)
            req.downloadDir = r.dir
            req.paused = !r.start
            _ = try? await self.appService.rpcSession?.addTorrent(req)
            LayoutState.saveLastUsedDir(r.dir)
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc func startSelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            try? await self.appService.rpcSession?.startTorrents(ids: ids)
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc func stopSelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            try? await self.appService.rpcSession?.stopTorrents(ids: ids)
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc func forceStartSelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            try? await self.appService.rpcSession?.forceStartTorrents(ids: ids)
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc func verifySelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            try? await self.appService.rpcSession?.verifyTorrents(ids: ids)
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc func removeSelected(_ sender: Any?) {
        guard !appService.isMutating else { return }
        confirmRemove(deleteData: false)
    }

    @objc func removeWithDataSelected(_ sender: Any?) {
        guard !appService.isMutating else { return }
        confirmRemove(deleteData: true)
    }

    private func confirmRemove(deleteData: Bool) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = S.RemoveAlert.message(count: ids.count, deleteData: deleteData)
        alert.informativeText = S.RemoveAlert.detail(deleteData: deleteData)
        alert.addButton(withTitle: deleteData ? S.RemoveAlert.deleteButton : S.RemoveAlert.removeButton)
        alert.addButton(withTitle: S.RemoveAlert.cancelButton)
        alert.alertStyle = deleteData ? .critical : .warning
        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            self.appService.setMutating(true)
            Task { [appService = self.appService] in
                try? await appService.rpcSession?.removeTorrents(ids: ids, deleteData: deleteData)
                // Clear selection before refresh so removed torrents don't get re-selected
                appService.setSelection(Set())
                await appService.refresh()
                appService.setMutating(false)
            }
        }
    }

    @objc func setLocationSelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating, let window = view.window else { return }
        let sheet = SetLocationSheet(appService: appService)
        sheet.currentPath = appService.selectedTorrents.first?.downloadDir ?? ""
        Task {
            let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
            let result: (path: String, move: Bool)? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let r = result, !r.path.isEmpty else { return }
            self.appService.setMutating(true)
            do {
                try await appService.rpcSession?.setLocation(ids: ids, location: r.path, move: r.move)
                LayoutState.saveLastUsedDir(r.path)
                await self.appService.refresh()
                self.appService.setMutating(false)
            } catch {
                self.appService.setMutating(false)
                showRPCError(error, in: window)
            }
        }
    }

    @objc func renameSelected(_ sender: Any?) {
        guard let torrent = appService.selectedTorrents.first,
              !appService.isMutating,
              let window = view.window else { return }
        let sheet = RenameSheet()
        sheet.nameField.stringValue = torrent.name
        Task {
            let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
            let newName: String? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let name = newName, !name.isEmpty, name != torrent.name else { return }
            self.appService.setMutating(true)
            do {
                try await appService.rpcSession?.renamePath(id: torrent.id, path: torrent.rootPathForRename, name: name)
                await self.appService.refresh()
                self.appService.setMutating(false)
            } catch {
                self.appService.setMutating(false)
                showRPCError(error, in: window)
            }
        }
    }

    @objc func reannounceSelected(_ sender: Any?) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            try? await self.appService.rpcSession?.reannounceTorrents(ids: ids)
            self.appService.setMutating(false)
        }
    }

    private func showRPCError(_ error: Error, in window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = S.ErrorAlert.title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: S.ErrorAlert.okButton)
        alert.beginSheetModal(for: window)
    }

    @objc private func deselectAll(_ sender: Any?) {
        tableView.deselectAll(sender)
    }

    @objc private func queueTop(_ s: Any?)    { moveQueue("top") }
    @objc private func queueUp(_ s: Any?)     { moveQueue("up") }
    @objc private func queueDown(_ s: Any?)   { moveQueue("down") }
    @objc private func queueBottom(_ s: Any?) { moveQueue("bottom") }

    private func moveQueue(_ dir: String) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        self.appService.setMutating(true)
        Task {
            switch dir {
            case "top":    try? await self.appService.rpcSession?.queueMoveTop(ids: ids)
            case "up":     try? await self.appService.rpcSession?.queueMoveUp(ids: ids)
            case "down":   try? await self.appService.rpcSession?.queueMoveDown(ids: ids)
            case "bottom": try? await self.appService.rpcSession?.queueMoveBottom(ids: ids)
            default: break
            }
            await self.appService.refresh()
            self.appService.setMutating(false)
        }
    }

    @objc private func rowDoubleClicked() {
        NotificationCenter.default.post(name: .toggleDetailsPanel, object: nil)
    }

    // MARK: - Priority actions

    @objc private func setPriorityHigh(_ sender: Any?)   { setPriority(.high) }
    @objc private func setPriorityNormal(_ sender: Any?) { setPriority(.normal) }
    @objc private func setPriorityLow(_ sender: Any?)    { setPriority(.low) }

    private func setPriority(_ priority: BandwidthPriority) {
        let ids = Array(appService.selectedIDs)
        guard !ids.isEmpty, !appService.isMutating else { return }
        appService.setMutating(true)
        Task {
            var patch = TorrentPatch()
            patch.bandwidthPriority = priority.rawValue
            try? await appService.rpcSession?.setTorrent(ids: ids, patch: patch)
            await appService.refresh()
            appService.setMutating(false)
        }
    }
}

// MARK: - NSMenuDelegate (header menu + context menu)

extension TorrentListController: NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Header menu: populate with column visibility + group-by options
        if menu === tableView.headerView?.menu {
            buildHeaderMenu(menu)
            return
        }
        // Context menu: update enabled states
        let hasSelection = !appService.selectedIDs.isEmpty
        menu.items.forEach { $0.isEnabled = hasSelection }
        // Select All / Deselect All are always enabled
        for item in menu.items {
            if item.action == #selector(NSResponder.selectAll(_:)) ||
               item.action == #selector(deselectAll) {
                item.isEnabled = true
            }
        }
        // Priority submenu: always enabled when there's a selection, show checkmarks
        if let prioItem = menu.items.first(where: { $0.submenu != nil && $0.title == S.ContextMenu.priority }) {
            prioItem.isEnabled = hasSelection
            if let sub = prioItem.submenu {
                let selected = appService.selectedTorrents
                let priorities = Set(selected.map { $0.bandwidthPriority })
                let current: BandwidthPriority? = priorities.count == 1 ? priorities.first : nil
                for subItem in sub.items {
                    subItem.isEnabled = hasSelection
                    subItem.state = (current?.rawValue == subItem.tag) ? .on : .off
                }
            }
        }
    }

    private func buildHeaderMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        // Column visibility section
        let colHeader = NSMenuItem(title: "Columns", action: nil, keyEquivalent: "")
        colHeader.isEnabled = false
        menu.addItem(colHeader)

        for col in tableView.tableColumns {
            let item = NSMenuItem(title: col.title, action: #selector(toggleColumn(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = col
            item.state = col.isHidden ? .off : .on
            // Name column is not hideable
            if col.identifier == .name { item.isEnabled = false }
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Group-by section
        let gbHeader = NSMenuItem(title: "Group By", action: nil, keyEquivalent: "")
        gbHeader.isEnabled = false
        menu.addItem(gbHeader)

        let noneItem = NSMenuItem(title: S.ContextMenu.groupNone, action: #selector(setGroupBy(_:)), keyEquivalent: "")
        noneItem.target = self
        noneItem.tag = -1
        noneItem.state = groupByKey == nil ? .on : .off
        menu.addItem(noneItem)

        let groupableKeys: [(String, SortKey)] = [(S.Column.status, .status), (S.Column.location, .location)]
        for (title, key) in groupableKeys {
            let item = NSMenuItem(title: title, action: #selector(setGroupBy(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            item.state = groupByKey == key ? .on : .off
            menu.addItem(item)
        }
    }

    @objc private func toggleColumn(_ sender: NSMenuItem) {
        guard let col = sender.representedObject as? NSTableColumn else { return }
        col.isHidden = !col.isHidden
        saveLayout()
    }

    @objc private func setGroupBy(_ sender: NSMenuItem) {
        if sender.tag == -1 {
            groupByKey = nil
        } else {
            groupByKey = sender.representedObject as? SortKey
        }
        saveLayout()
        refreshDisplay()
    }
}

// MARK: - TableViewDataSource

extension TorrentListController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { displayedRows.count }
}

// MARK: - TableViewDelegate

extension TorrentListController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if case .groupHeader = displayedRows[row] { return true }
        return false
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if case .groupHeader = displayedRows[row] { return false }
        return true
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < displayedRows.count else { return nil }

        // Group header — NSTableView calls viewFor with tableColumn=nil for isGroupRow rows
        if case .groupHeader(let title) = displayedRows[row] {
            guard tableColumn == nil else { return nil }
            let cellID = NSUserInterfaceItemIdentifier("GroupHeaderCell")
            let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView
                ?? {
                    let c = NSTableCellView()
                    c.identifier = cellID
                    let tf = NSTextField(labelWithString: "")
                    tf.translatesAutoresizingMaskIntoConstraints = false
                    tf.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
                    tf.textColor = Theme.comment
                    c.addSubview(tf)
                    c.textField = tf
                    NSLayoutConstraint.activate([
                        tf.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 4),
                        tf.trailingAnchor.constraint(equalTo: c.trailingAnchor),
                        tf.centerYAnchor.constraint(equalTo: c.centerYAnchor),
                    ])
                    return c
                }()
            cell.textField?.stringValue = title.uppercased()
            return cell
        }

        guard case .torrent(let torrent) = displayedRows[row], let col = tableColumn else { return nil }

        switch col.identifier {
        case .name:
            let id = NSUserInterfaceItemIdentifier("TorrentCell")
            let cell = tableView.makeView(withIdentifier: id, owner: nil) as? TorrentCell
                ?? TorrentCell(frame: .zero)
            cell.identifier = id
            cell.configure(torrent: torrent)
            return cell

        case .progress:
            let id = NSUserInterfaceItemIdentifier("ProgressCell")
            let cell = tableView.makeView(withIdentifier: id, owner: nil) as? ProgressBarView
                ?? ProgressBarView(frame: .zero)
            cell.identifier = id
            cell.progress = torrent.percentDone
            cell.progressText = "\(Int(torrent.percentDone * 100))%"
            cell.barColor = torrent.status == .seeding ? Theme.green : Theme.blue
            return cell

        default:
            let cellID = NSUserInterfaceItemIdentifier("LabelCell_\(col.identifier.rawValue)")
            let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField
                ?? makeTextCell(identifier: cellID)
            cell.stringValue = textValue(for: col.identifier, torrent: torrent)
            return cell
        }
    }

    private func makeTextCell(identifier: NSUserInterfaceItemIdentifier) -> NSTextField {
        let f = NSTextField(labelWithString: "")
        f.identifier = identifier
        f.font = .systemFont(ofSize: NSFont.systemFontSize)
        return f
    }

    private func textValue(for id: NSUserInterfaceItemIdentifier, torrent: Torrent) -> String {
        switch id {
        case .status:     return Formatters.formatStatusString(torrent)
        case .size:       return Formatters.formatBytes(torrent.totalSize)
        case .downloaded: return Formatters.formatBytes(torrent.downloadedEver)
        case .uploaded:   return Formatters.formatBytes(torrent.uploadedEver)
        case .ratio:      return Formatters.formatRatio(torrent.uploadRatio)
        case .dlSpeed:    return torrent.rateDownload > 0 ? Formatters.formatSpeed(torrent.rateDownload) : "—"
        case .ulSpeed:    return torrent.rateUpload > 0   ? Formatters.formatSpeed(torrent.rateUpload)   : "—"
        case .eta:        return torrent.eta >= 0 ? Formatters.formatETA(torrent.eta) : "—"
        case .seeds:      return "\(torrent.peersSendingToUs)"
        case .peers:      return "\(torrent.peersConnected)"
        case .queue:      return "\(torrent.queuePosition + 1)"
        case .location:   return torrent.downloadDir
        default:          return ""
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if case .groupHeader = displayedRows[row] { return 22 }
        return 22
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !suppressSelectionChange else { return }
        var ids = Set<Int>()
        tableView.selectedRowIndexes.forEach { idx in
            if case .torrent(let t) = displayedRows[idx] { ids.insert(t.id) }
        }
        self.appService.setSelection(ids)
    }

    // Sort on header click
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        guard let key = SortKey(rawValue: tableColumn.identifier.rawValue) else { return }
        if sortKey == key { sortAscending.toggle() } else { sortKey = key; sortAscending = true }
        saveLayout()
        refreshDisplay()
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let toggleDetailsPanel = Notification.Name("toggleDetailsPanel")
}

// MARK: - Drag-aware scroll view

private final class DragScrollView: NSScrollView {
    weak var dragDelegate: TorrentListController?

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dragDelegate?.draggingEntered(sender) ?? []
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dragDelegate?.performDragOperation(sender) ?? false
    }
}

// MARK: - Drag-and-drop (.torrent files)

extension TorrentListController {

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return torrentURLs(from: sender).isEmpty ? [] : .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = torrentURLs(from: sender)
        guard !urls.isEmpty, !appService.isMutating, let window = view.window else { return false }
        for url in urls {
            guard let sheet = try? AddTorrentSheet(torrentURL: url, appService: appService) else { continue }
            Task {
                let sheetWindow = NSWindow(contentViewController: sheet)
                    sheetWindow.backgroundColor = Theme.bg
                sheetWindow.styleMask = [.titled, .closable, .resizable]
                sheetWindow.setContentSize(sheet.preferredContentSize)
                let result: AddTorrentResult? = await withCheckedContinuation { cont in
                    sheet.presentedContinuation = cont
                    window.beginSheet(sheetWindow)
                }
                guard let r = result else { return }
                self.appService.setMutating(true)
                var req = AddTorrentRequest(metainfo: r.torrentData.base64EncodedString())
                req.downloadDir = r.downloadDir
                req.paused = r.paused
                req.bandwidthPriority = r.bandwidthPriority
                req.filesWanted = r.filesWanted
                req.filesUnwanted = r.filesUnwanted
                req.priorityHigh = r.priorityHigh
                req.priorityLow = r.priorityLow
                _ = try? await self.appService.rpcSession?.addTorrent(req)
                await self.appService.refresh()
                self.appService.setMutating(false)
            }
        }
        return true
    }

    private func torrentURLs(from info: NSDraggingInfo) -> [URL] {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true,
                      .urlReadingContentsConformToTypes: ["org.bittorrent.torrent", "public.data"]]) as? [URL]
        else { return [] }
        return items.filter { $0.pathExtension.lowercased() == "torrent" }
    }
}
