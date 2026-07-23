import AppKit
import TransmissionRPC

// MARK: - Shared helpers

/// Returns known server-side download directories for use in a combo box.
/// The last-used directory (if any) is always first.
@MainActor
func knownServerDirs(appService: AppService) -> [String] {
    var dirs: [String] = []
    // Last-used dir first — makes repeat downloads go to the same place
    if let last = LayoutState.load().lastUsedDir, !last.isEmpty { dirs.append(last) }
    // Server default
    if let d = appService.session?.downloadDir, !d.isEmpty, !dirs.contains(d) { dirs.append(d) }
    // Incomplete dir
    if let s = appService.session, s.incompleteDirEnabled, !s.incompleteDir.isEmpty,
       !dirs.contains(s.incompleteDir) { dirs.append(s.incompleteDir) }
    // All unique dirs from active torrents
    for t in appService.torrents where !t.downloadDir.isEmpty && !dirs.contains(t.downloadDir) {
        dirs.append(t.downloadDir)
    }
    return dirs
}

/// Populate an NSComboBox with known server dirs. Selects the first (default) entry.
@MainActor
func populateDirCombo(_ combo: NSComboBox, appService: AppService) {
    let dirs = knownServerDirs(appService: appService)
    combo.removeAllItems()
    combo.addItems(withObjectValues: dirs)
    if !dirs.isEmpty { combo.selectItem(at: 0) }
}

// MARK: - AddLinkSheet

final class AddLinkSheet: NSViewController {
    private let appService: AppService

    private let urlField   = NSTextField()
    private let nameLabel  = NSTextField(labelWithString: "")
    private let dirCombo   = NSComboBox()
    private let startCheck = NSButton(checkboxWithTitle: S.AddURL.startWhenAdded, target: nil, action: nil)
    private let addButton  = NSButton(title: S.AddURL.addButton, target: nil, action: nil)
    private let cancelBtn  = NSButton(title: S.AddURL.cancelButton, target: nil, action: nil)

    var prefill: String = ""
    var presentedContinuation: CheckedContinuation<(url: String, dir: String, start: Bool)?, Never>?

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        urlField.stringValue = prefill
        if prefill.hasPrefix("magnet:") {
            nameLabel.stringValue = magnetDisplayName(prefill)
            nameLabel.isHidden = false
            urlField.isHidden = true
        } else {
            nameLabel.isHidden = true
            urlField.isHidden = false
        }
        populateDirCombo(dirCombo, appService: appService)
    }

    override func loadView() {
        urlField.placeholderString = "magnet:? or https://"
        urlField.font = .systemFont(ofSize: NSFont.systemFontSize)

        nameLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.maximumNumberOfLines = 0
        nameLabel.preferredMaxLayoutWidth = 300
        nameLabel.isHidden = true

        dirCombo.isEditable = true
        dirCombo.completes = true
        dirCombo.font = .systemFont(ofSize: NSFont.systemFontSize)
        NSLayoutConstraint.activate([
            dirCombo.widthAnchor.constraint(equalToConstant: 300),
        ])

        startCheck.state = (appService.session?.startAddedTorrents ?? true) ? .on : .off

        addButton.bezelStyle = .rounded
        addButton.keyEquivalent = "\r"
        addButton.target = self; addButton.action = #selector(addTapped)

        cancelBtn.bezelStyle = .rounded
        cancelBtn.keyEquivalent = "\u{1b}"
        cancelBtn.target = self; cancelBtn.action = #selector(cancelTapped)

        let urlRow = NSStackView(views: [urlField, nameLabel])
        urlRow.orientation = .horizontal
        NSLayoutConstraint.activate([
            urlField.widthAnchor.constraint(equalToConstant: 300),
            nameLabel.widthAnchor.constraint(equalToConstant: 300),
        ])

        let form = NSGridView(views: [
            [NSTextField(labelWithString: S.AddURL.labelURL),    urlRow],
            [NSTextField(labelWithString: S.AddURL.labelSaveTo), dirCombo],
            [NSView(),                                           startCheck],
        ])
        form.column(at: 0).width = 90
        form.column(at: 0).xPlacement = .trailing
        form.rowSpacing = 8; form.columnSpacing = 8

        let buttons = NSStackView(views: [cancelBtn, addButton])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let main = NSStackView(views: [form, buttons])
        main.orientation = .vertical; main.alignment = .trailing
        main.spacing = 16
        main.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        main.translatesAutoresizingMaskIntoConstraints = false

        let v = NSView()
        v.frame = NSRect(x: 0, y: 0, width: 460, height: 180)
        v.addSubview(main)
        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            main.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            main.topAnchor.constraint(equalTo: v.topAnchor),
            main.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        view = v
    }

    // MARK: - Actions

    @objc private func addTapped() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: (
            url: urlField.stringValue,
            dir: dirCombo.stringValue,
            start: startCheck.state == .on
        ))
    }

    @objc private func cancelTapped() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: nil)
    }

    private func magnetDisplayName(_ magnet: String) -> String {
        guard let components = URLComponents(string: magnet) else { return S.AddURL.magnetFallback }
        if let dn = components.queryItems?.first(where: { $0.name == "dn" })?.value, !dn.isEmpty {
            return dn
        }
        if let xt = components.queryItems?.first(where: { $0.name == "xt" })?.value {
            return String((xt.components(separatedBy: ":").last ?? xt).prefix(16)) + "…"
        }
        return S.AddURL.magnetFallback
    }
}

// MARK: - SetLocationSheet

final class SetLocationSheet: NSViewController {
    private let appService: AppService
    /// Pre-fill with the torrent's current download dir before presenting.
    var currentPath: String = ""
    private let pathCombo  = NSComboBox()
    private let moveCheck  = NSButton(checkboxWithTitle: S.SetLocation.moveData, target: nil, action: nil)
    private let okButton   = NSButton(title: S.SetLocation.okButton, target: nil, action: nil)
    private let cancelBtn  = NSButton(title: S.SetLocation.cancelButton, target: nil, action: nil)

    var presentedContinuation: CheckedContinuation<(path: String, move: Bool)?, Never>?

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        populateDirCombo(pathCombo, appService: appService)
        // If the current path is in the list select it, else type it in
        if let idx = (pathCombo.objectValues as? [String])?.firstIndex(of: currentPath) {
            pathCombo.selectItem(at: idx)
        } else if !currentPath.isEmpty {
            pathCombo.stringValue = currentPath
        }
    }

    override func loadView() {
        pathCombo.isEditable = true
        pathCombo.completes = true
        pathCombo.font = .systemFont(ofSize: NSFont.systemFontSize)
        NSLayoutConstraint.activate([
            pathCombo.widthAnchor.constraint(equalToConstant: 300),
        ])

        moveCheck.state = .on
        okButton.bezelStyle = .rounded; okButton.keyEquivalent = "\r"
        okButton.target = self; okButton.action = #selector(ok)
        cancelBtn.bezelStyle = .rounded; cancelBtn.keyEquivalent = "\u{1b}"
        cancelBtn.target = self; cancelBtn.action = #selector(cancel)

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: S.SetLocation.labelLocation), pathCombo],
            [NSView(),                                                   moveCheck],
        ])
        grid.column(at: 0).width = 80
        grid.column(at: 0).xPlacement = .trailing
        grid.rowSpacing = 8; grid.columnSpacing = 8

        let buttons = NSStackView(views: [cancelBtn, okButton])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let stack = NSStackView(views: [grid, buttons])
        stack.orientation = .vertical; stack.alignment = .trailing
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let v = NSView()
        v.frame = NSRect(x: 0, y: 0, width: 440, height: 140)
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            stack.topAnchor.constraint(equalTo: v.topAnchor),
            stack.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        view = v
    }

    @objc private func ok() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: (path: pathCombo.stringValue, move: moveCheck.state == .on))
    }
    @objc private func cancel() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: nil)
    }
}

// MARK: - RenameSheet

final class RenameSheet: NSViewController {
    let nameField = NSTextField()    // accessible for prefill
    private let okButton  = NSButton(title: S.Rename.okButton, target: nil, action: nil)
    private let cancelBtn = NSButton(title: S.Rename.cancelButton, target: nil, action: nil)

    var presentedContinuation: CheckedContinuation<String?, Never>?

    override func loadView() {
        nameField.font = .systemFont(ofSize: NSFont.systemFontSize)
        okButton.bezelStyle = .rounded; okButton.keyEquivalent = "\r"
        okButton.target = self; okButton.action = #selector(ok)
        cancelBtn.bezelStyle = .rounded; cancelBtn.keyEquivalent = "\u{1b}"
        cancelBtn.target = self; cancelBtn.action = #selector(cancel)

        let grid = NSGridView(views: [[NSTextField(labelWithString: S.Rename.labelNewName), nameField]])
        grid.column(at: 0).width = 80; grid.column(at: 0).xPlacement = .trailing; grid.columnSpacing = 8

        let buttons = NSStackView(views: [cancelBtn, okButton])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let stack = NSStackView(views: [grid, buttons])
        stack.orientation = .vertical; stack.alignment = .trailing
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let v = NSView()
        v.frame = NSRect(x: 0, y: 0, width: 340, height: 100)
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            stack.topAnchor.constraint(equalTo: v.topAnchor),
            stack.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        view = v
    }

    @objc private func ok() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: nameField.stringValue)
    }
    @objc private func cancel() {
        view.window?.sheetParent?.endSheet(view.window!)
        presentedContinuation?.resume(returning: nil)
    }
}
