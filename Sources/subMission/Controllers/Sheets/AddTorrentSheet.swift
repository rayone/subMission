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
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.maximumNumberOfLines = 0
        nameLabel.preferredMaxLayoutWidth = 360

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
            let col0 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
            col0.title = S.AddTorrent.colName; col0.width = 280
            let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
            col1.title = S.AddTorrent.colSize; col1.width = 80

            let ov = NSOutlineView()
            ov.addTableColumn(col0)
            ov.addTableColumn(col1)
            ov.outlineTableColumn = col0
            ov.dataSource = self; ov.delegate = self
            ov.allowsMultipleSelection = false
            ov.autoresizesOutlineColumn = false
            self.outlineView = ov

            let sv = NSScrollView()
            sv.documentView = ov
            sv.hasVerticalScroller = true
            sv.autohidesScrollers = true
            sv.borderType = .bezelBorder
            sv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sv.heightAnchor.constraint(equalToConstant: 180),
                sv.widthAnchor.constraint(equalToConstant: 460),
            ])
            fileTreeView = sv

            ov.reloadData()
            ov.expandItem(rootNode, expandChildren: false)
        } else {
            fileTreeView = NSView()
            fileTreeView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fileTreeView.heightAnchor.constraint(equalToConstant: 0),
            ])
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
        NSLayoutConstraint.activate([
            nameLabel.widthAnchor.constraint(equalToConstant: 360),
            dirCombo.widthAnchor.constraint(equalToConstant: 360),
        ])

        let buttons = NSStackView(views: [cancelButton, addButton])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let main = NSStackView(views: [form, fileTreeView, buttons])
        main.orientation = .vertical; main.alignment = .trailing; main.spacing = 12
        main.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        main.translatesAutoresizingMaskIntoConstraints = false

        let v = NSView()
        v.frame = NSRect(x: 0, y: 0, width: 500, height: fileCount > 1 ? 400 : 210)
        v.addSubview(main)
        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            main.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            main.topAnchor.constraint(equalTo: v.topAnchor),
            main.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        view = v
    }

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
        guard let node = item as? FileNode else { return nil }
        let id = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("name")
        let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTextField
            ?? NSTextField(labelWithString: "")
        cell.identifier = id
        switch id.rawValue {
        case "name": cell.stringValue = node.name
        case "size": cell.stringValue = node.size > 0 ? Formatters.formatBytes(Int64(node.size)) : ""
        default: break
        }
        return cell
    }
}
