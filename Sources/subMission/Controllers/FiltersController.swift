import AppKit

// MARK: - Filter node model

enum FilterNode: Equatable {
    // Status filters
    case all
    case downloading
    case seeding
    case completed
    case active
    case inactive
    case error
    // Label filters
    case noLabel
    case label(String)

    var title: String {
        switch self {
        case .all:          return S.Filter.all
        case .downloading:  return S.Filter.downloading
        case .seeding:      return S.Filter.seeding
        case .completed:    return S.Filter.completed
        case .active:       return S.Filter.active
        case .inactive:     return S.Filter.inactive
        case .error:        return S.Filter.error
        case .noLabel:      return S.Filter.noLabel
        case .label(let l): return l
        }
    }

    var image: NSImage? {
        let sym: String
        switch self {
        case .all:          sym = "list.bullet"
        case .downloading:  sym = "arrow.down.circle"
        case .seeding:      sym = "arrow.up.circle"
        case .completed:    sym = "checkmark.circle"
        case .active:       sym = "bolt.circle"
        case .inactive:     sym = "pause.circle"
        case .error:        sym = "exclamationmark.circle"
        case .noLabel, .label: sym = "tag"
        }
        return NSImage(systemSymbolName: sym, accessibilityDescription: nil)
    }
}

// MARK: - FiltersController

final class FiltersController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private let appService: AppService

    private let outlineView = NSOutlineView()

    // Section headers
    private let statusHeader = S.Filter.statusHeader
    private let labelsHeader = S.Filter.labelsHeader

    private var statusNodes: [FilterNode] = [.all, .downloading, .seeding, .completed, .active, .inactive, .error]
    private var labelNodes: [FilterNode] = []

    private var observerToken: ObserverToken?
    private var selectedNode: FilterNode = .all

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        outlineView.style = .sourceList
        outlineView.headerView = nil
        outlineView.rowHeight = 24
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.allowsEmptySelection = false
        outlineView.autoresizesOutlineColumn = true
        outlineView.indentationPerLevel = 8
        outlineView.backgroundColor = Theme.bg

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("filter"))
        col.isEditable = false
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col

        let scroll = NSScrollView()
        scroll.documentView = outlineView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.backgroundColor = Theme.bg
        scroll.drawsBackground = true

        view = scroll
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observerToken = appService.addObserver { [weak self] event in
            switch event {
            case .torrentsUpdated:
                self?.reloadLabels()
            default: break
            }
        }
        outlineView.reloadData()
        // Expand both sections
        outlineView.expandItem(statusHeader)
        outlineView.expandItem(labelsHeader)
        // Select "All"
        selectNode(.all)
    }

    deinit { observerToken?.cancel() }

    private func reloadLabels() {
        let labels = appService.allLabels
        var nodes: [FilterNode] = [.noLabel]
        nodes += labels.map { FilterNode.label($0) }
        if nodes != labelNodes {
            labelNodes = nodes
            outlineView.reloadItem(labelsHeader, reloadChildren: true)
        }
    }

    private func selectNode(_ node: FilterNode) {
        selectedNode = node
        applyFilter(node)
        // Find and select the row
        for row in 0..<outlineView.numberOfRows {
            if let item = outlineView.item(atRow: row) as? FilterNode, item == node {
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                break
            }
        }
    }

    private func applyFilter(_ node: FilterNode) {
        var state = FilterState()
        state.searchText = appService.filterState.searchText // preserve search
        switch node {
        case .all:          state.statusFilter = .all
        case .downloading:  state.statusFilter = .downloading
        case .seeding:      state.statusFilter = .seeding
        case .completed:    state.statusFilter = .completed
        case .active:       state.statusFilter = .active
        case .inactive:     state.statusFilter = .inactive
        case .error:        state.statusFilter = .error
        case .noLabel:      state.statusFilter = .all; state.labelFilter = ""
        case .label(let l): state.statusFilter = .all; state.labelFilter = l
        }
        appService.filterState = state
    }

    // MARK: - OutlineView DataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return 2 } // two section headers
        if let s = item as? String {
            if s == statusHeader { return statusNodes.count }
            if s == labelsHeader { return labelNodes.count }
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        item is String
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { return index == 0 ? statusHeader : labelsHeader }
        if let s = item as? String {
            if s == statusHeader { return statusNodes[index] }
            if s == labelsHeader { return labelNodes[index] }
        }
        return ""
    }

    // MARK: - OutlineView Delegate

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        item is String
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        item is FilterNode
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let header = item as? String {
            let id = NSUserInterfaceItemIdentifier("HeaderCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTextField
                ?? NSTextField(labelWithString: "")
            cell.identifier = id
            cell.stringValue = header
            cell.font = .boldSystemFont(ofSize: 11)
            cell.textColor = Theme.comment
            return cell
        }
        if let node = item as? FilterNode {
            let id = NSUserInterfaceItemIdentifier("FilterCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView
                ?? NSTableCellView()
            cell.identifier = id

            if cell.textField == nil {
                let tf = NSTextField(labelWithString: "")
                tf.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(tf)
                cell.textField = tf
                NSLayoutConstraint.activate([
                    tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 20),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                    tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
                let iv = NSImageView()
                iv.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    iv.widthAnchor.constraint(equalToConstant: 14),
                    iv.heightAnchor.constraint(equalToConstant: 14),
                ])
                cell.addSubview(iv)
                cell.imageView = iv
                NSLayoutConstraint.activate([
                    iv.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    iv.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            }

            cell.textField?.stringValue = node.title
            cell.imageView?.image = node.image

            // Show count badge
            let count = torrentCount(for: node)
            if count > 0 {
                cell.textField?.stringValue = "\(node.title)  \(count)"
            }
            return cell
        }
        return nil
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let row = outlineView.selectedRow
        if let node = outlineView.item(atRow: row) as? FilterNode {
            selectedNode = node
            applyFilter(node)
        }
    }

    // MARK: - Count helpers

    private func torrentCount(for node: FilterNode) -> Int {
        let torrents = appService.torrents
        switch node {
        case .all:          return torrents.count
        case .downloading:  return torrents.filter { $0.status == .downloading || $0.status == .queuedDownload }.count
        case .seeding:      return torrents.filter { $0.status == .seeding || $0.status == .queuedSeed }.count
        case .completed:    return torrents.filter { $0.isFinished }.count
        case .active:       return torrents.filter { $0.rateDownload > 0 || $0.rateUpload > 0 }.count
        case .inactive:     return torrents.filter { $0.rateDownload == 0 && $0.rateUpload == 0 && $0.status != .stopped }.count
        case .error:        return torrents.filter { $0.error != 0 }.count
        case .noLabel:      return torrents.filter { $0.labels.isEmpty }.count
        case .label(let l): return torrents.filter { $0.labels.contains(l) }.count
        }
    }
}
