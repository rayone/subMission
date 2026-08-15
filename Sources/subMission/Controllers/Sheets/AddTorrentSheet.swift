import AppKit
import TransmissionRPC

// MARK: - AddTorrentSheet

final class AddTorrentSheet: NSViewController {

    // MARK: - File tree node

    final class FileNode {
        let name: String
        var children: [FileNode] = []
        var fileIndex: Int?        // non-nil for leaf nodes
        var size: Int = 0
        var wanted: Bool = true
        var priority: Int = 0      // 0=normal, 1=high, -1=low

        init(_ name: String) { self.name = name }
    }

    // MARK: - State

    private let appService: AppService
    private let torrentData: Data
    private let torrentURL: URL
    private var rootNode: FileNode = FileNode("")
    private var fileCount: Int = 0

    var presentedContinuation: CheckedContinuation<AddTorrentResult?, Never>?

    // MARK: - Controls

    private let nameLabel      = NSTextField(labelWithString: "")
    private let dirCombo       = NSComboBox()
    private let startCheck     = NSButton(checkboxWithTitle: S.AddTorrent.startWhenAdded, target: nil, action: nil)
    private let priorityPopup  = NSPopUpButton()
    private let addButton      = NSButton(title: S.AddTorrent.addButton, target: nil, action: nil)
    private let cancelButton   = NSButton(title: S.AddTorrent.cancelButton, target: nil, action: nil)
    private var outlineView: NSOutlineView!

    // MARK: - Init

    init(torrentURL: URL, appService: AppService) throws {
        self.appService = appService
        self.torrentURL = torrentURL
        self.torrentData = try Data(contentsOf: torrentURL)
        super.init(nibName: nil, bundle: nil)
        buildFileTree()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Bencode parsing → file tree

    private func buildFileTree() {
        guard let torrent = try? BencodeDecoder().decode(torrentData),
              let info = torrent["info"]?.dict else { return }

        let root = FileNode(info["name"]?.string ?? torrentURL.lastPathComponent)

        if let files = info["files"]?.list {
            // Multi-file torrent
            for (i, fileVal) in files.enumerated() {
                guard let fileDict = fileVal.dict,
                      let pathList = fileDict["path"]?.list else { continue }
                let parts = pathList.compactMap { $0.string }
                let length = fileDict["length"]?.int ?? 0
                insertFile(into: root, path: parts, index: i, size: length)
                fileCount += 1
            }
        } else {
            // Single-file torrent
            let length = info["length"]?.int ?? 0
            let leaf = FileNode(info["name"]?.string ?? "")
            leaf.fileIndex = 0
            leaf.size = length
            root.children.append(leaf)
            fileCount = 1
        }

        rollupSizes(root)
        rootNode = root
    }

    private func insertFile(into node: FileNode, path: [String], index: Int, size: Int) {
        guard !path.isEmpty else { return }
        if path.count == 1 {
            let leaf = FileNode(path[0])
            leaf.fileIndex = index
            leaf.size = size
            node.children.append(leaf)
        } else {
            let child = node.children.first(where: { $0.name == path[0] && $0.fileIndex == nil })
                ?? { let n = FileNode(path[0]); node.children.append(n); return n }()
            insertFile(into: child, path: Array(path.dropFirst()), index: index, size: size)
        }
    }

    @discardableResult
    private func rollupSizes(_ node: FileNode) -> Int {
        if node.fileIndex != nil { return node.size }
        node.size = node.children.reduce(0) { $0 + rollupSizes($1) }
        return node.size
    }

    // MARK: - View

    override func loadView() {
        nameLabel.stringValue = rootNode.name
        nameLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 2
        nameLabel.isSelectable = true

        dirCombo.isEditable = true
        dirCombo.completes = true
        dirCombo.font = .systemFont(ofSize: NSFont.systemFontSize)
        populateDirCombo(dirCombo, appService: appService)

        startCheck.state = (appService.session?.startAddedTorrents ?? true) ? .on : .off

        priorityPopup.removeAllItems()
        priorityPopup.addItems(withTitles: [S.AddTorrent.priorityHigh, S.AddTorrent.priorityNormal, S.AddTorrent.priorityLow])
        priorityPopup.selectItem(at: 1)

        addButton.bezelStyle = .rounded; addButton.keyEquivalent = "\r"
        addButton.target = self; addButton.action = #selector(addTapped)
        cancelButton.bezelStyle = .rounded; cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.target = self; cancelButton.action = #selector(cancelTapped)

        // Build outline if multi-file
        let fileTreeView: NSView
        if fileCount > 1 {
            let wantedCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("wanted"))
            wantedCol.title = ""; wantedCol.width = 24; wantedCol.minWidth = 24; wantedCol.maxWidth = 24
            let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
            nameCol.title = S.AddTorrent.colName; nameCol.width = 300; nameCol.minWidth = 120
            nameCol.resizingMask = [.userResizingMask, .autoresizingMask]
            let sizeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
            sizeCol.title = S.AddTorrent.colSize; sizeCol.width = 80; sizeCol.minWidth = 60

            let ov = NSOutlineView()
            ov.addTableColumn(wantedCol)
            ov.addTableColumn(nameCol)
            ov.addTableColumn(sizeCol)
            ov.outlineTableColumn = nameCol
            ov.dataSource = self; ov.delegate = self
            ov.allowsMultipleSelection = true
            ov.autoresizesOutlineColumn = true
            ov.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            ov.rowHeight = 20
            ov.usesAlternatingRowBackgroundColors = true

            // Context menu for copying file names
            let ctxMenu = NSMenu()
            ctxMenu.addItem(NSMenuItem(title: "Copy Name", action: #selector(copySelectedNames), keyEquivalent: "c"))
            ctxMenu.items.forEach { $0.target = self }
            ov.menu = ctxMenu

            self.outlineView = ov

            let sv = NSScrollView()
            sv.documentView = ov
            sv.hasVerticalScroller = true
            sv.autohidesScrollers = true
            sv.borderType = .bezelBorder
            sv.translatesAutoresizingMaskIntoConstraints = false
            // Flexible height — no fixed constraint
            sv.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
            fileTreeView = sv

            ov.reloadData()
            ov.expandItem(rootNode, expandChildren: false)
        } else {
            fileTreeView = NSView()
            fileTreeView.translatesAutoresizingMaskIntoConstraints = false
            fileTreeView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }

        let form = NSGridView(views: [
            [NSTextField(labelWithString: S.AddTorrent.labelName),     nameLabel],
            [NSTextField(labelWithString: S.AddTorrent.labelSaveTo),   dirCombo],
            [NSTextField(labelWithString: S.AddTorrent.labelPriority), priorityPopup],
            [NSView(),                                                  startCheck],
        ])
        form.column(at: 0).width = 80
        form.column(at: 0).xPlacement = .trailing
        form.rowSpacing = 7; form.columnSpacing = 8
        form.translatesAutoresizingMaskIntoConstraints = false

        let buttons = NSStackView(views: [cancelButton, addButton])
        buttons.orientation = .horizontal; buttons.spacing = 8
        buttons.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        form.translatesAutoresizingMaskIntoConstraints = false
        fileTreeView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(form)
        container.addSubview(fileTreeView)
        container.addSubview(buttons)

        // Hugging priorities: form and buttons should not stretch, file tree fills space
        form.setContentHuggingPriority(.defaultHigh, for: .vertical)
        buttons.setContentHuggingPriority(.defaultHigh, for: .vertical)
        fileTreeView.setContentHuggingPriority(.defaultLow, for: .vertical)
        fileTreeView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            fileTreeView.topAnchor.constraint(equalTo: form.bottomAnchor, constant: 12),
            fileTreeView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            fileTreeView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            buttons.topAnchor.constraint(equalTo: fileTreeView.bottomAnchor, constant: 12),
            buttons.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            nameLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
            dirCombo.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
        ])

        view = container
        preferredContentSize = NSSize(width: 540, height: fileCount > 1 ? 480 : 220)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = view.window {
            window.minSize = NSSize(width: 420, height: fileCount > 1 ? 340 : 200)
        }
    }

    // MARK: - Actions

    @objc private func addTapped() {
        let priority: Int
        switch priorityPopup.indexOfSelectedItem {
        case 0:  priority = 1
        case 2:  priority = -1
        default: priority = 0
        }

        var filesWanted: [Int]? = nil
        var filesUnwanted: [Int]? = nil
        var priorityHigh: [Int]? = nil
        var priorityLow: [Int]? = nil

        if fileCount > 1 {
            var wanted: [Int] = []; var unwanted: [Int] = []
            var high: [Int] = []; var low: [Int] = []
            collectFileSelections(rootNode, &wanted, &unwanted, &high, &low)
            if !unwanted.isEmpty { filesWanted = wanted; filesUnwanted = unwanted }
            if !high.isEmpty    { priorityHigh = high }
            if !low.isEmpty     { priorityLow  = low  }
        }

        let result = AddTorrentResult(
            torrentData: torrentData,
            downloadDir: dirCombo.stringValue,
            paused: startCheck.state != .on,
            bandwidthPriority: priority,
            filesWanted: filesWanted,
            filesUnwanted: filesUnwanted,
            priorityHigh: priorityHigh,
            priorityLow: priorityLow
        )
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: result)
    }

    @objc private func cancelTapped() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: nil)
    }

    @objc private func wantedToggled(_ sender: NSButton) {
        let row = outlineView.row(for: sender)
        guard row >= 0, let node = outlineView.item(atRow: row) as? FileNode else { return }
        let newState = sender.state == .on
        setWanted(node, newState)
        outlineView.reloadData()
    }

    @objc private func copySelectedNames() {
        var names: [String] = []
        let rows = outlineView.selectedRowIndexes
        if rows.isEmpty {
            // If no selection, copy all file names
            collectAllNames(rootNode, &names)
        } else {
            for row in rows {
                if let node = outlineView.item(atRow: row) as? FileNode {
                    if node.children.isEmpty {
                        names.append(node.name)
                    } else {
                        collectAllNames(node, &names)
                    }
                }
            }
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(names.joined(separator: "\n"), forType: .string)
    }

    private func collectAllNames(_ node: FileNode, _ names: inout [String]) {
        if node.children.isEmpty {
            names.append(node.name)
        } else {
            for child in node.children {
                collectAllNames(child, &names)
            }
        }
    }

    private func setWanted(_ node: FileNode, _ wanted: Bool) {
        node.wanted = wanted
        for child in node.children {
            setWanted(child, wanted)
        }
    }

    private func collectFileSelections(
        _ node: FileNode,
        _ wanted: inout [Int], _ unwanted: inout [Int],
        _ high: inout [Int], _ low: inout [Int]
    ) {
        if let idx = node.fileIndex {
            if node.wanted { wanted.append(idx) } else { unwanted.append(idx) }
            if node.priority == 1  { high.append(idx) }
            if node.priority == -1 { low.append(idx)  }
        } else {
            node.children.forEach { collectFileSelections($0, &wanted, &unwanted, &high, &low) }
        }
    }
}

// MARK: - AddTorrentResult

struct AddTorrentResult {
    let torrentData: Data
    let downloadDir: String
    let paused: Bool
    let bandwidthPriority: Int
    let filesWanted: [Int]?
    let filesUnwanted: [Int]?
    let priorityHigh: [Int]?
    let priorityLow: [Int]?
}

// MARK: - NSOutlineViewDataSource / Delegate

extension AddTorrentSheet: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? FileNode else { return rootNode.children.count }
        return node.children.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? FileNode else { return rootNode.children[index] }
        return node.children[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? FileNode else { return false }
        return !node.children.isEmpty
    }
}

extension AddTorrentSheet: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FileNode, let col = tableColumn else { return nil }

        switch col.identifier.rawValue {
        case "wanted":
            let id = NSUserInterfaceItemIdentifier("wanted_check")
            let btn = outlineView.makeView(withIdentifier: id, owner: nil) as? NSButton
                ?? NSButton(checkboxWithTitle: "", target: nil, action: nil)
            btn.identifier = id
            if node.children.isEmpty {
                btn.state = node.wanted ? .on : .off
            } else {
                let allWanted = allChildrenWanted(node)
                let noneWanted = allChildrenUnwanted(node)
                if allWanted { btn.state = .on }
                else if noneWanted { btn.state = .off }
                else { btn.allowsMixedState = true; btn.state = .mixed }
            }
            btn.target = self
            btn.action = #selector(wantedToggled(_:))
            return btn

        case "name":
            let id = col.identifier
            let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTextField
                ?? NSTextField(labelWithString: "")
            cell.identifier = id
            cell.stringValue = node.name
            cell.isSelectable = true
            cell.lineBreakMode = .byTruncatingTail
            return cell

        case "size":
            let id = col.identifier
            let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTextField
                ?? NSTextField(labelWithString: "")
            cell.identifier = id
            cell.stringValue = node.size > 0 ? Formatters.formatBytes(Int64(node.size)) : ""
            return cell

        default:
            return nil
        }
    }

    private func allChildrenWanted(_ node: FileNode) -> Bool {
        if node.children.isEmpty { return node.wanted }
        return node.children.allSatisfy { allChildrenWanted($0) }
    }

    private func allChildrenUnwanted(_ node: FileNode) -> Bool {
        if node.children.isEmpty { return !node.wanted }
        return node.children.allSatisfy { allChildrenUnwanted($0) }
    }
}
