import AppKit
import TransmissionRPC

// MARK: - TorrentDetailsController

@MainActor
final class TorrentDetailsController: NSViewController {
    private let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var tabView: NSTabView!
    private var infoTab:     InfoTabController!
    private var filesTab:    FilesTabController!
    private var trackersTab: TrackersTabController!
    private var peersTab:    PeersTabController!
    private var limitsTab:   LimitsTabController!

    private var observerToken: ObserverToken?
    private var currentTorrent: Torrent?

    override func loadView() {
        view = NSView()
        buildTabs()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observerToken = appService.addObserver { [weak self] event in
            switch event {
            case .torrentsUpdated, .selectionChanged:
                self?.updateContent()
            default: break
            }
        }
        updateContent()
    }

    deinit { observerToken?.cancel() }

    // MARK: - Build tabs

    private func buildTabs() {
        infoTab     = InfoTabController(appService: appService)
        filesTab    = FilesTabController(appService: appService)
        trackersTab = TrackersTabController(appService: appService)
        peersTab    = PeersTabController(appService: appService)
        limitsTab   = LimitsTabController(appService: appService)

        tabView = NSTabView()
        tabView.tabViewType = .topTabsBezelBorder
        tabView.translatesAutoresizingMaskIntoConstraints = false

        let tabs: [(String, NSViewController)] = [
            (S.Details.tabInfo, infoTab), (S.Details.tabFiles, filesTab), (S.Details.tabTrackers, trackersTab),
            (S.Details.tabPeers, peersTab), (S.Details.tabLimits, limitsTab)
        ]
        for (title, vc) in tabs {
            _ = vc.view                        // force loadView before configure is called
            let item = NSTabViewItem(viewController: vc)
            item.label = title
            tabView.addTabViewItem(item)
        }

        tabView.delegate = self

        view.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.topAnchor.constraint(equalTo: view.topAnchor),
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Content update

    private func updateContent() {
        let selected = appService.selectedTorrents
        if selected.count == 1 {
            let t = selected[0]
            currentTorrent = t
            infoTab.configure(torrent: t)
            filesTab.configure(torrent: t)
            trackersTab.configure(torrent: t)
            peersTab.configure(torrent: t)
            limitsTab.configure(torrent: t)
        } else if selected.isEmpty {
            clearAll()
        } else {
            showMultiSelect(count: selected.count)
        }
    }

    private func clearAll() {
        currentTorrent = nil
        infoTab.showPlaceholder(S.Details.noSelection)
        filesTab.showPlaceholder(S.Details.noSelection)
        trackersTab.showPlaceholder(S.Details.noSelection)
        peersTab.showPlaceholder(S.Details.noSelection)
        limitsTab.showPlaceholder(S.Details.noSelection)
    }

    private func showMultiSelect(count: Int) {
        let msg = S.Details.multiSelection(count: count)
        infoTab.showPlaceholder(msg)
        filesTab.showPlaceholder(msg)
        trackersTab.showPlaceholder(msg)
        peersTab.showPlaceholder(msg)
        limitsTab.configure(torrents: appService.selectedTorrents)
    }
}

extension TorrentDetailsController: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        // No-op — tab index no longer persisted
    }
}

// MARK: - InfoTabController

final class InfoTabController: NSViewController {
    private let appService: AppService
    private var grid: NSGridView!

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private var placeholderLabel: NSTextField?
    private var currentTorrent: Torrent?

    // Identity
    private let nameVal       = NSTextField(labelWithString: "—")
    private let hashVal       = NSTextField(labelWithString: "—")
    private let commentVal    = NSTextField(labelWithString: "—")
    private let creatorVal    = NSTextField(labelWithString: "—")
    private let createdVal    = NSTextField(labelWithString: "—")
    private let privateVal    = NSTextField(labelWithString: "—")
    private let locationVal   = NSTextField(labelWithString: "—")
    private let renameBtn     = NSButton(image: NSImage(systemSymbolName: "pencil", accessibilityDescription: "Rename")!, target: nil, action: nil)
    private let setLocBtn     = NSButton(image: NSImage(systemSymbolName: "pencil", accessibilityDescription: "Set Location")!, target: nil, action: nil)
    // Transfer
    private let statusVal     = NSTextField(labelWithString: "—")
    private let downloadedVal = NSTextField(labelWithString: "—")
    private let uploadedVal   = NSTextField(labelWithString: "—")
    private let ratioVal      = NSTextField(labelWithString: "—")
    private let dlSpeedVal    = NSTextField(labelWithString: "—")
    private let ulSpeedVal    = NSTextField(labelWithString: "—")
    private let dlTimeVal     = NSTextField(labelWithString: "—")
    private let ulTimeVal     = NSTextField(labelWithString: "—")
    // Progress
    private let totalSizeVal  = NSTextField(labelWithString: "—")
    private let haveVal       = NSTextField(labelWithString: "—")
    private let remainVal     = NSTextField(labelWithString: "—")
    private let corruptVal    = NSTextField(labelWithString: "—")
    private let addedVal      = NSTextField(labelWithString: "—")
    private let completedVal  = NSTextField(labelWithString: "—")
    private let lastActiveVal = NSTextField(labelWithString: "—")

    override func loadView() {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        buildGrid(in: container)

        scroll.documentView = container
        // Pin document view width to clip view so vertical-only scrolling works
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])
        view = scroll
    }

    private func buildGrid(in container: NSView) {
        hashVal.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        hashVal.isSelectable = true
        locationVal.isSelectable = true

        // Edit buttons
        for btn in [renameBtn, setLocBtn] {
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.imageScaling = .scaleProportionallyDown
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 16),
                btn.heightAnchor.constraint(equalToConstant: 16),
            ])
            btn.toolTip = btn === renameBtn ? S.Info.renameTip : S.Info.setLocTip
        }
        renameBtn.target = self;  renameBtn.action  = #selector(renameAction)
        setLocBtn.target = self;  setLocBtn.action  = #selector(setLocationAction)

        func makeLabel(_ text: String) -> NSTextField {
            let lbl = NSTextField(labelWithString: text + ":")
            lbl.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            lbl.alignment = .right
            return lbl
        }
        func val(_ v: NSTextField) -> NSTextField {
            v.font = .systemFont(ofSize: NSFont.systemFontSize)
            v.lineBreakMode = .byTruncatingTail
            return v
        }
        func editRow(_ label: String, _ value: NSTextField, _ btn: NSButton) -> [NSView] {
            let stack = NSStackView(views: [value, btn])
            stack.orientation = .horizontal; stack.spacing = 4; stack.alignment = .centerY
            _ = val(value)
            return [makeLabel(label), stack]
        }
        func row(_ label: String, _ value: NSTextField) -> [NSView] {
            return [makeLabel(label), val(value)]
        }

        let rows: [[NSView]] = [
            editRow(S.Info.name,         nameVal,       renameBtn),
            row(S.Info.hash,             hashVal),
            row(S.Info.comment,          commentVal),
            row(S.Info.creator,          creatorVal),
            row(S.Info.created,          createdVal),
            row(S.Info.isPrivate,        privateVal),
            editRow(S.Info.location,     locationVal,   setLocBtn),
            [NSView(), NSView()],
            row(S.Info.statusRow,        statusVal),
            row(S.Info.downloaded,       downloadedVal),
            row(S.Info.uploaded,         uploadedVal),
            row(S.Info.ratio,            ratioVal),
            row(S.Info.dlSpeed,          dlSpeedVal),
            row(S.Info.ulSpeed,          ulSpeedVal),
            row(S.Info.timeDl,           dlTimeVal),
            row(S.Info.timeSeeding,      ulTimeVal),
            [NSView(), NSView()],
            row(S.Info.totalSize,        totalSizeVal),
            row(S.Info.have,             haveVal),
            row(S.Info.remaining,        remainVal),
            row(S.Info.corrupt,          corruptVal),
            row(S.Info.added,            addedVal),
            row(S.Info.completed,        completedVal),
            row(S.Info.lastActive,       lastActiveVal),
        ]

        grid = NSGridView(views: rows)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).width = 110
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 300
        grid.rowSpacing = 3
        grid.columnSpacing = 8

        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(greaterThanOrEqualTo: grid.bottomAnchor, constant: 8),
        ])
    }

    func configure(torrent: Torrent) {
        currentTorrent = torrent
        placeholderLabel?.isHidden = true
        grid?.isHidden = false
        renameBtn.isHidden = false
        setLocBtn.isHidden = false

        nameVal.stringValue       = torrent.name
        hashVal.stringValue       = torrent.hashString
        commentVal.stringValue    = torrent.comment.isEmpty ? "—" : torrent.comment
        creatorVal.stringValue    = torrent.creator.isEmpty ? "—" : torrent.creator
        createdVal.stringValue    = Formatters.formatDate(torrent.dateCreated)
        privateVal.stringValue    = torrent.isPrivate ? S.Info.yes : S.Info.no
        locationVal.stringValue   = torrent.downloadDir
        statusVal.stringValue     = Formatters.formatStatusString(torrent)
        downloadedVal.stringValue = Formatters.formatBytes(torrent.downloadedEver)
        uploadedVal.stringValue   = Formatters.formatBytes(torrent.uploadedEver)
        ratioVal.stringValue      = Formatters.formatRatio(torrent.uploadRatio)
        dlSpeedVal.stringValue    = torrent.rateDownload > 0 ? Formatters.formatSpeed(torrent.rateDownload) : "—"
        ulSpeedVal.stringValue    = torrent.rateUpload > 0   ? Formatters.formatSpeed(torrent.rateUpload)   : "—"
        dlTimeVal.stringValue     = Formatters.formatDuration(Int64(torrent.secondsDownloading))
        ulTimeVal.stringValue     = Formatters.formatDuration(torrent.secondsSeeding)
        totalSizeVal.stringValue  = Formatters.formatBytes(torrent.totalSize)
        haveVal.stringValue       = Formatters.formatBytes(torrent.haveValid + torrent.haveUnchecked)
        remainVal.stringValue     = Formatters.formatBytes(torrent.leftUntilDone)
        corruptVal.stringValue    = Formatters.formatBytes(torrent.corruptEver)
        addedVal.stringValue      = Formatters.formatDate(torrent.addedDate)
        completedVal.stringValue  = torrent.doneDate > 0 ? Formatters.formatDate(torrent.doneDate) : "—"
        lastActiveVal.stringValue = torrent.activityDate > 0 ? Formatters.formatDate(torrent.activityDate) : "—"
    }

    func showPlaceholder(_ msg: String) {
        currentTorrent = nil
        renameBtn.isHidden = true
        setLocBtn.isHidden = true
        grid?.isHidden = true
        if placeholderLabel == nil {
            let lbl = NSTextField(labelWithString: "")
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.textColor = Theme.comment
            lbl.alignment = .center
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            placeholderLabel = lbl
        }
        placeholderLabel?.stringValue = msg
        placeholderLabel?.isHidden = false
    }

    // MARK: - Edit actions

    @objc private func renameAction() {
        guard let torrent = currentTorrent, let window = view.window else { return }
        let sheet = RenameSheet()
        sheet.nameField.stringValue = torrent.name
        Task {
            let sheetWindow = NSWindow(contentViewController: sheet)
            let newName: String? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let name = newName, !name.isEmpty, name != torrent.name else { return }
            do {
                try await appService.rpcSession?.renamePath(id: torrent.id, path: torrent.rootPathForRename, name: name)
                await appService.refresh()
            } catch {
                showRPCError(error, in: window)
            }
        }
    }

    @objc private func setLocationAction() {
        guard let torrent = currentTorrent, let window = view.window else { return }
        let sheet = SetLocationSheet(appService: appService)
        sheet.currentPath = torrent.downloadDir
        Task {
            let sheetWindow = NSWindow(contentViewController: sheet)
            let result: (path: String, move: Bool)? = await withCheckedContinuation { cont in
                sheet.presentedContinuation = cont
                window.beginSheet(sheetWindow)
            }
            guard let r = result, !r.path.isEmpty else { return }
            do {
                try await appService.rpcSession?.setLocation(ids: [torrent.id], location: r.path, move: r.move)
                LayoutState.saveLastUsedDir(r.path)
                await appService.refresh()
            } catch {
                showRPCError(error, in: window)
            }
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
}

// MARK: - FilesTabController

final class FilesTabController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private let appService: AppService

    private var outlineView: NSOutlineView!
    private var roots: [FileNode] = []
    private var currentTorrentID: Int = -1
    private var placeholderLabel: NSTextField?

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        outlineView = NSOutlineView()
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.usesAlternatingRowBackgroundColors = true
        outlineView.rowHeight = 20

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fname"))
        nameCol.title = S.Files.colName; nameCol.width = 240; nameCol.minWidth = 100
        let sizeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fsize"))
        sizeCol.title = S.Files.colSize; sizeCol.width = 80; sizeCol.minWidth = 60
        let progCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fprog"))
        progCol.title = S.Files.colProgress; progCol.width = 70; progCol.minWidth = 50
        let prioCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fprio"))
        prioCol.title = S.Files.colPriority; prioCol.width = 80; prioCol.minWidth = 60
        let wantCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fwant"))
        wantCol.title = S.Files.colWanted; wantCol.width = 55; wantCol.minWidth = 50

        [nameCol, sizeCol, progCol, prioCol, wantCol].forEach { outlineView.addTableColumn($0) }
        outlineView.outlineTableColumn = nameCol

        let scroll = NSScrollView()
        scroll.documentView = outlineView
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        view = scroll
    }

    func configure(torrent: Torrent) {
        placeholderLabel?.isHidden = true
        outlineView?.isHidden = false
        if torrent.id != currentTorrentID {
            // Different torrent — full rebuild, expand all
            currentTorrentID = torrent.id
            roots = FileTreeBuilder.build(from: torrent.files)
            outlineView.reloadData()
            outlineView.expandItem(nil, expandChildren: true)
        } else {
            // Same torrent — save expanded state, reload, restore
            let expanded = expandedPaths()
            
            // Rebuild tree if the file count changed, otherwise update bytesCompleted inline
            var filesChanged = false
            var currentFilesCount = 0
            func countLeafs(_ node: FileNode) {
                if node.isFolder {
                    node.children.forEach(countLeafs)
                } else {
                    currentFilesCount += 1
                }
            }
            roots.forEach(countLeafs)
            
            if currentFilesCount != torrent.files.count {
                filesChanged = true
            }

            if filesChanged {
                roots = FileTreeBuilder.build(from: torrent.files)
            } else {
                FileTreeBuilder.updateProgress(in: roots, with: torrent.files)
            }
            
            outlineView.reloadData()
            restoreExpanded(expanded)
        }
    }

    /// Collect name-paths of every currently expanded folder node.
    private func expandedPaths() -> Set<String> {
        var paths = Set<String>()
        func walk(_ node: FileNode, prefix: String) {
            let path = prefix.isEmpty ? node.name : "\(prefix)/\(node.name)"
            if node.isFolder && outlineView.isItemExpanded(node) {
                paths.insert(path)
                node.children.forEach { walk($0, prefix: path) }
            }
        }
        roots.forEach { walk($0, prefix: "") }
        return paths
    }

    /// Re-expand nodes whose name-path was in the saved set.
    private func restoreExpanded(_ paths: Set<String>) {
        func walk(_ node: FileNode, prefix: String) {
            let path = prefix.isEmpty ? node.name : "\(prefix)/\(node.name)"
            if node.isFolder {
                if paths.contains(path) {
                    outlineView.expandItem(node)
                    node.children.forEach { walk($0, prefix: path) }
                }
            }
        }
        roots.forEach { walk($0, prefix: "") }
    }

    func showPlaceholder(_ msg: String) {
        outlineView?.isHidden = true
        if placeholderLabel == nil {
            let lbl = NSTextField(labelWithString: "")
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.textColor = Theme.comment
            lbl.alignment = .center
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            placeholderLabel = lbl
        }
        placeholderLabel?.stringValue = msg
        placeholderLabel?.isHidden = false
    }

    // MARK: OutlineView DataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        item == nil ? roots.count : (item as? FileNode)?.children.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? FileNode)?.isFolder ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        item == nil ? roots[index] : (item as! FileNode).children[index]
    }

    // MARK: OutlineView Delegate

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FileNode, let col = tableColumn else { return nil }
        switch col.identifier.rawValue {
        case "fname":
            let cell = outlineView.makeView(withIdentifier: col.identifier, owner: nil) as? NSTableCellView
                ?? NSTableCellView()
            cell.identifier = col.identifier
            if cell.textField == nil {
                let tf = NSTextField(labelWithString: "")
                tf.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(tf)
                cell.textField = tf
                NSLayoutConstraint.activate([
                    tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                    tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            }
            cell.textField?.stringValue = node.name
            return cell

        case "fsize":
            return labelCell(col, text: Formatters.formatBytes(node.totalLength))

        case "fprog":
            return labelCell(col, text: "\(Int(node.progress * 100))%")

        case "fprio":
            // BUG FIX #1: priority popup
            let id = NSUserInterfaceItemIdentifier("fprio_popup")
            let popup = outlineView.makeView(withIdentifier: id, owner: nil) as? NSPopUpButton
                ?? NSPopUpButton(frame: .zero, pullsDown: false)
            popup.identifier = id
            popup.removeAllItems()
            popup.addItems(withTitles: [S.Files.priorityHigh, S.Files.priorityNormal, S.Files.priorityLow])
            switch node.priority {
            case .high:   popup.selectItem(at: 0)
            case .normal: popup.selectItem(at: 1)
            case .low:    popup.selectItem(at: 2)
            }
            popup.target = self
            popup.action = #selector(priorityChanged(_:))
            popup.tag = outlineView.row(forItem: item)
            return popup

        case "fwant":
            // BUG FIX #1: wanted checkbox
            let id = NSUserInterfaceItemIdentifier("fwant_check")
            let btn = outlineView.makeView(withIdentifier: id, owner: nil) as? NSButton
                ?? NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.identifier = id
            btn.state = node.wanted ? .on : .off
            btn.target = self
            btn.action = #selector(wantedChanged(_:))
            btn.tag = outlineView.row(forItem: item)
            return btn

        default:
            return nil
        }
    }

    private func labelCell(_ col: NSTableColumn, text: String) -> NSTextField {
        let id = NSUserInterfaceItemIdentifier("\(col.identifier.rawValue)_label")
        let f = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTextField
            ?? NSTextField(labelWithString: "")
        f.identifier = id
        f.stringValue = text
        f.font = .systemFont(ofSize: NSFont.systemFontSize)
        return f
    }

    // MARK: BUG FIX #1 — File wanted / priority actions

    @objc private func wantedChanged(_ sender: NSButton) {
        let row = sender.tag
        guard let node = outlineView.item(atRow: row) as? FileNode else { return }
        let indices = collectLeafIndices(node)
        guard !indices.isEmpty else { return }   // Never send empty arrays
        let want = sender.state == .on
        let torrentID = currentTorrentID
        Task {
            var patch = TorrentPatch()
            if want { patch.filesWanted   = indices }
            else    { patch.filesUnwanted = indices }
            try? await appService.rpcSession?.setTorrent(ids: [torrentID], patch: patch)
            await appService.refresh()
        }
    }

    @objc private func priorityChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        guard let node = outlineView.item(atRow: row) as? FileNode else { return }
        let indices = collectLeafIndices(node)
        guard !indices.isEmpty else { return }
        let prio: BandwidthPriority = sender.indexOfSelectedItem == 0 ? .high
                                    : sender.indexOfSelectedItem == 2 ? .low
                                    : .normal
        let torrentID = currentTorrentID
        Task {
            var patch = TorrentPatch()
            switch prio {
            case .high:   patch.priorityHigh   = indices
            case .normal: patch.priorityNormal = indices
            case .low:    patch.priorityLow    = indices
            }
            try? await appService.rpcSession?.setTorrent(ids: [torrentID], patch: patch)
            await appService.refresh()
        }
    }

    private func collectLeafIndices(_ node: FileNode) -> [Int] {
        if let idx = node.fileIndex { return [idx] }
        return node.children.flatMap { collectLeafIndices($0) }
    }
}

// MARK: - TrackersTabController

final class TrackersTabController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let appService: AppService
    private var tableView: NSTableView!
    private var editView: NSTextView!
    private var updateButton: NSButton!
    private var stats: [TrackerStat] = []
    private var currentTorrentID: Int = -1
    private var placeholderLabel: NSTextField?

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 20
        tableView.usesAlternatingRowBackgroundColors = true

        let cols: [(String, String, CGFloat)] = [
            ("tracker", S.Trackers.colTracker, 140),
            ("tstatus", S.Trackers.colStatus,  160),
            ("tseeds",  S.Trackers.colSeeds,   55),
            ("tpeers",  S.Trackers.colPeers,   55),
            ("tdl",     S.Trackers.colDL,      55),
        ]
        for (id, title, w) in cols {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            col.title = title; col.width = w; col.minWidth = 40
            tableView.addTableColumn(col)
        }

        let tableScroll = NSScrollView()
        tableScroll.documentView = tableView
        tableScroll.hasVerticalScroller = true
        tableScroll.borderType = .noBorder

        editView = NSTextView()
        editView.isEditable = true
        editView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        let editScroll = NSScrollView()
        editScroll.documentView = editView
        editScroll.hasVerticalScroller = true
        editScroll.borderType = .bezelBorder

        updateButton = NSButton(title: S.Trackers.updateButton, target: self, action: #selector(updateTrackers))
        updateButton.bezelStyle = .rounded

        let v = NSView()
        tableScroll.translatesAutoresizingMaskIntoConstraints = false
        editScroll.translatesAutoresizingMaskIntoConstraints = false
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(tableScroll)
        v.addSubview(editScroll)
        v.addSubview(updateButton)
        NSLayoutConstraint.activate([
            tableScroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            tableScroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            tableScroll.topAnchor.constraint(equalTo: v.topAnchor),
            tableScroll.heightAnchor.constraint(equalTo: v.heightAnchor, multiplier: 0.6),
            editScroll.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 4),
            editScroll.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -4),
            editScroll.topAnchor.constraint(equalTo: tableScroll.bottomAnchor, constant: 4),
            editScroll.bottomAnchor.constraint(equalTo: updateButton.topAnchor, constant: -4),
            updateButton.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8),
            updateButton.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -8),
        ])
        view = v
    }

    func configure(torrent: Torrent) {
        placeholderLabel?.isHidden = true
        tableView?.isHidden = false
        currentTorrentID = torrent.id
        stats = torrent.trackerStats
        tableView.reloadData()
        editView.string = torrent.trackerList
    }

    func showPlaceholder(_ msg: String) {
        tableView?.isHidden = true
        if placeholderLabel == nil {
            let lbl = NSTextField(labelWithString: "")
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.textColor = Theme.comment; lbl.alignment = .center
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            placeholderLabel = lbl
        }
        placeholderLabel?.stringValue = msg; placeholderLabel?.isHidden = false
    }

    @objc private func updateTrackers() {
        let newList = editView.string
        let tid = currentTorrentID
        Task {
            var patch = TorrentPatch()
            patch.trackerList = newList
            try? await appService.rpcSession?.setTorrent(ids: [tid], patch: patch)
            await appService.refresh()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { stats.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < stats.count, let col = tableColumn else { return nil }
        let s = stats[row]
        let text: String
        switch col.identifier.rawValue {
        case "tracker": text = s.host.isEmpty ? s.announce : s.host
        case "tstatus": text = s.lastAnnounceResult.isEmpty ? "—" : s.lastAnnounceResult
        case "tseeds":  text = "\(s.seederCount)"
        case "tpeers":  text = "\(s.leecherCount)"
        case "tdl":     text = "\(s.downloadCount)"
        default:        text = ""
        }
        
        let id = NSUserInterfaceItemIdentifier("\(col.identifier.rawValue)_label")
        let f = tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField
            ?? NSTextField(labelWithString: "")
        f.identifier = id
        f.stringValue = text
        f.font = .systemFont(ofSize: NSFont.systemFontSize)
        return f
    }
}

// MARK: - PeersTabController

final class PeersTabController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let appService: AppService
    private var tableView: NSTableView!
    private var peersFromLabel: NSTextField!
    private var peers: [Peer] = []
    private var placeholderLabel: NSTextField?

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        tableView = NSTableView()
        tableView.dataSource = self; tableView.delegate = self
        tableView.rowHeight = 20
        tableView.usesAlternatingRowBackgroundColors = true

        let cols: [(String, String, CGFloat)] = [
            ("paddress",  S.Peers.colAddress,  60),
            ("pclient",   S.Peers.colClient,   120),
            ("pprogress", S.Peers.colProgress, 60),
            ("pdlrate",   S.Peers.colDLRate,   70),
            ("pulrate",   S.Peers.colULRate,   70),
            ("pflags",    S.Peers.colFlags,    80),
        ]
        for (id, title, w) in cols {
            let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            c.title = title; c.width = w; c.minWidth = 40
            tableView.addTableColumn(c)
        }

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        peersFromLabel = NSTextField(labelWithString: "")
        peersFromLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        peersFromLabel.textColor = Theme.comment

        let v = NSView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        peersFromLabel.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(scroll)
        v.addSubview(peersFromLabel)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: v.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: peersFromLabel.topAnchor, constant: -2),
            peersFromLabel.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8),
            peersFromLabel.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -4),
        ])
        view = v
    }

    func configure(torrent: Torrent) {
        placeholderLabel?.isHidden = true
        tableView?.isHidden = false
        peers = torrent.peers
        tableView.reloadData()
        let pf = torrent.peersFrom
        peersFromLabel.stringValue = S.Peers.fromSummary(
            tracker: pf.fromTracker, dht: pf.fromDht, pex: pf.fromPex,
            lpd: pf.fromLpd, incoming: pf.fromIncoming, cache: pf.fromCache
        )
    }

    func showPlaceholder(_ msg: String) {
        tableView?.isHidden = true
        if placeholderLabel == nil {
            let lbl = NSTextField(labelWithString: "")
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.textColor = Theme.comment; lbl.alignment = .center
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            placeholderLabel = lbl
        }
        placeholderLabel?.stringValue = msg; placeholderLabel?.isHidden = false
    }

    func numberOfRows(in tableView: NSTableView) -> Int { peers.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < peers.count, let col = tableColumn else { return nil }
        let p = peers[row]
        let text: String
        switch col.identifier.rawValue {
        case "paddress":  text = "\(p.address):\(p.port)"
        case "pclient":   text = p.clientName
        case "pprogress": text = "\(Int(p.progress * 100))%"
        case "pdlrate":   text = p.rateToClient > 0 ? Formatters.formatSpeed(p.rateToClient) : "—"
        case "pulrate":   text = p.rateToPeer   > 0 ? Formatters.formatSpeed(p.rateToPeer)   : "—"
        case "pflags":    text = p.flagStr
        default:          text = ""
        }
        
        let id = NSUserInterfaceItemIdentifier("\(col.identifier.rawValue)_label")
        let f = tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField
            ?? NSTextField(labelWithString: "")
        f.identifier = id
        f.stringValue = text
        f.font = .systemFont(ofSize: NSFont.systemFontSize)
        return f
    }
}

// MARK: - LimitsTabController

final class LimitsTabController: NSViewController {
    private let appService: AppService
    private var container: NSView!
    private var placeholderLabel: NSTextField?

    private let font: NSFont = .systemFont(ofSize: 12)

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Speed
    private let dlLimitCheck  = LimitsCheck()
    private let dlLimitField  = LimitsField(placeholder: S.Limits.kbps)
    private let ulLimitCheck  = LimitsCheck()
    private let ulLimitField  = LimitsField(placeholder: S.Limits.kbps)
    private let honorCheck    = LimitsCheck()
    private let bwPrioSeg     = NSSegmentedControl(labels: [S.Limits.bwPriorityLow, S.Limits.bwPriorityNormal, S.Limits.bwPriorityHigh],
                                                    trackingMode: .selectOne, target: nil, action: nil)
    // Seeding
    private let seedRatioPopup = NSPopUpButton()
    private let seedRatioField = LimitsField(placeholder: S.Limits.ratio)
    private let seedIdlePopup  = NSPopUpButton()
    private let seedIdleField  = LimitsField(placeholder: S.Limits.minutes)

    // Other
    private let peerLimitField = LimitsField(placeholder: "")
    private let seqDlCheck     = LimitsCheck()

    private var currentIDs: [Int] = []

    override func loadView() {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        buildForm(in: container)
        scroll.documentView = container
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])
        view = scroll
    }

    private func row(_ label: String, _ control: NSView?, tip: String? = nil) -> (String, NSView?, String?) {
        (label, control, tip)
    }

    private func buildForm(in v: NSView) {
        seedRatioPopup.removeAllItems()
        seedRatioPopup.addItems(withTitles: [S.Limits.seedModeGlobal, S.Limits.seedModeStop, S.Limits.seedModeForever])
        seedRatioPopup.font = font

        seedIdlePopup.removeAllItems()
        seedIdlePopup.addItems(withTitles: [S.Limits.seedModeGlobal, S.Limits.seedModeStop, S.Limits.seedModeForever])
        seedIdlePopup.font = font

        bwPrioSeg.font = font

        // Wire
        for ctl: NSControl in [dlLimitCheck, dlLimitField, ulLimitCheck, ulLimitField,
                                 honorCheck, bwPrioSeg, seedRatioPopup, seedRatioField,
                                 seedIdlePopup, seedIdleField, peerLimitField, seqDlCheck] {
            ctl.target = self; ctl.action = #selector(applyLimits)
        }

        // Inline control: [check] [field] for speed rows
        func checkField(_ check: LimitsCheck, _ field: LimitsField, _ unit: String) -> NSView {
            let unitLbl = NSTextField(labelWithString: unit)
            unitLbl.font = font; unitLbl.textColor = Theme.comment
            let s = NSStackView(views: [check, field, unitLbl])
            s.orientation = .horizontal; s.spacing = 4
            return s
        }

        let grid = limitsGrid([
            row(S.Limits.sectionSpeed, nil),
            row(S.Limits.download,     checkField(dlLimitCheck, dlLimitField, S.Limits.kbps),  tip: S.Limits.downloadLimitTip),
            row(S.Limits.upload,       checkField(ulLimitCheck, ulLimitField, S.Limits.kbps),  tip: S.Limits.uploadLimitTip),
            row(S.Limits.honorSession, honorCheck,    tip: S.Limits.honorSessionTip),
            row(S.Limits.priority,     bwPrioSeg,     tip: S.Limits.priorityTip),
            row(S.Limits.sectionSeeding, nil),
            row(S.Limits.ratioMode,    seedRatioPopup, tip: S.Limits.ratioModeTip),
            row(S.Limits.ratioLimit,   seedRatioField, tip: S.Limits.ratioLimitTip),
            row(S.Limits.idleMode,     seedIdlePopup,  tip: S.Limits.idleModeTip),
            row(S.Limits.idleLimit,    seedIdleField,  tip: S.Limits.idleLimitTip),
            row(S.Limits.sectionOther, nil),
            row(S.Limits.peerLimit,    peerLimitField, tip: S.Limits.peerLimitTip),
            row(S.Limits.sequentialDL, seqDlCheck,     tip: S.Limits.sequentialDLTip),
        ])

        v.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8),
            grid.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8),
            grid.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            v.bottomAnchor.constraint(greaterThanOrEqualTo: grid.bottomAnchor, constant: 8),
        ])
    }

    /// Build an NSGridView from (label, control?) rows.
    /// Rows with nil control are section headers spanning both columns.
    private func limitsGrid(_ rows: [(String, NSView?, String?)]) -> NSView {
        let grid = NSGridView()
        grid.rowSpacing = 4
        grid.columnSpacing = 8
        grid.translatesAutoresizingMaskIntoConstraints = false

        for (labelText, control, tip) in rows {
            if control == nil {
                // Section header row spanning both columns
                let hdr = NSTextField(labelWithString: labelText)
                hdr.font = .systemFont(ofSize: 10, weight: .semibold)
                hdr.textColor = Theme.comment
                hdr.translatesAutoresizingMaskIntoConstraints = false
                let spacer = NSGridCell.emptyContentView
                let gridRow = grid.addRow(with: [hdr, spacer])
                gridRow.topPadding = 8
                continue
            }
            let lbl = NSTextField(labelWithString: labelText)
            lbl.alignment = .right
            lbl.font = font
            lbl.textColor = Theme.comment
            lbl.translatesAutoresizingMaskIntoConstraints = false
            if let t = tip { lbl.toolTip = t; control!.toolTip = t }
            // Apply font to eligible controls
            if let tf = control as? NSTextField, tf.isEditable { tf.font = font }
            else if let btn = control as? NSButton { btn.font = font }
            grid.addRow(with: [lbl, control!])
        }

        if grid.numberOfColumns >= 2 {
            grid.column(at: 0).width = 100
            grid.column(at: 0).xPlacement = .trailing
        }
        return grid
    }

    func configure(torrent: Torrent) { configure(torrents: [torrent]) }

    func configure(torrents: [Torrent]) {
        placeholderLabel?.isHidden = true
        container?.isHidden = false
        currentIDs = torrents.map(\.id)
        guard let t = torrents.first else { return }

        dlLimitCheck.state       = t.downloadLimited ? .on : .off
        dlLimitField.stringValue = "\(t.downloadLimit)"
        ulLimitCheck.state       = t.uploadLimited ? .on : .off
        ulLimitField.stringValue = "\(t.uploadLimit)"
        honorCheck.state         = t.honorsSessionLimits ? .on : .off
        bwPrioSeg.selectedSegment = t.bandwidthPriority == .high ? 2 : t.bandwidthPriority == .low ? 0 : 1
        seedRatioPopup.selectItem(at: t.seedRatioMode.rawValue)
        seedRatioField.stringValue = t.seedRatioMode == .useTorrent ? String(format: "%.2f", t.seedRatioLimit) : ""
        seedIdlePopup.selectItem(at: t.seedIdleMode.rawValue)
        seedIdleField.stringValue  = t.seedIdleMode == .useTorrent ? "\(t.seedIdleLimit)" : ""
        peerLimitField.stringValue = "\(t.peerLimit)"
        seqDlCheck.state           = t.sequentialDownload ? .on : .off
    }

    func showPlaceholder(_ msg: String) {
        container?.isHidden = true
        if placeholderLabel == nil {
            let lbl = NSTextField(labelWithString: "")
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.textColor = Theme.comment; lbl.alignment = .center
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            placeholderLabel = lbl
        }
        placeholderLabel?.stringValue = msg; placeholderLabel?.isHidden = false
    }

    @objc private func applyLimits() {
        guard !currentIDs.isEmpty else { return }
        var patch = TorrentPatch()
        patch.downloadLimited     = dlLimitCheck.state == .on
        patch.downloadLimit       = Int(dlLimitField.stringValue) ?? 0
        patch.uploadLimited       = ulLimitCheck.state == .on
        patch.uploadLimit         = Int(ulLimitField.stringValue) ?? 0
        patch.honorsSessionLimits = honorCheck.state == .on
        patch.bandwidthPriority   = bwPrioSeg.selectedSegment == 2 ? 1
                                  : bwPrioSeg.selectedSegment == 0 ? -1 : 0
        patch.seedRatioMode       = seedRatioPopup.indexOfSelectedItem
        patch.seedRatioLimit      = Double(seedRatioField.stringValue)
        patch.seedIdleMode        = seedIdlePopup.indexOfSelectedItem
        patch.seedIdleLimit       = Int(seedIdleField.stringValue) ?? 0
        patch.peerLimit           = Int(peerLimitField.stringValue) ?? 0
        patch.sequentialDownload  = seqDlCheck.state == .on
        let ids = currentIDs
        Task {
            try? await appService.rpcSession?.setTorrent(ids: ids, patch: patch)
            await appService.refresh()
        }
    }
}

// MARK: - LimitsTabController helpers

/// Title-less checkbox (tick only) — label goes in the grid's left column.
private final class LimitsCheck: NSButton {
    init() {
        super.init(frame: .zero)
        title = ""
        setButtonType(.switch)
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Compact text field for limits.
private final class LimitsField: NSTextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        bezelStyle = .roundedBezel
        font = .systemFont(ofSize: 12)
        placeholderString = placeholder
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 72),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
