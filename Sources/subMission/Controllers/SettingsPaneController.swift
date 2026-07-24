import AppKit
import TransmissionRPC

// MARK: - SettingsPaneController

final class SettingsPaneController: NSViewController {
    private let appService: AppService

    // Connection
    private let hostField    = PaneField()
    private let rpcPortField = PaneField()
    private let pathField    = PaneField()
    private let sslCheck     = PaneCheck()
    private let userField    = PaneField()
    private let passField    = PaneSecure()
    private let pollField    = PaneField()
    private let testButton   = NSButton(title: S.Settings.Connection.testButton, target: nil, action: nil)
    private let testResult   = NSTextField(labelWithString: "")

    // Download
    private let dlDirField  = PaneField()
    private let incompField = PaneField(placeholder: S.Settings.disabled)
    private let startCheck  = PaneCheck()
    private let trashCheck  = PaneCheck()
    private let renameCheck = PaneCheck()

    // Speed  (empty = unlimited)
    private let dlLimitField = PaneField(placeholder: S.Settings.unlimited)
    private let ulLimitField = PaneField(placeholder: S.Settings.unlimited)
    private let altDlField   = PaneField()
    private let altUlField   = PaneField()

    // Queue  (empty = unlimited)
    private let dlQueueField   = PaneField(placeholder: S.Settings.unlimited)
    private let seedQueueField = PaneField(placeholder: S.Settings.unlimited)
    private let seedRatioField = PaneField(placeholder: S.Settings.unlimited)
    private let idleField      = PaneField(placeholder: S.Settings.unlimited)

    // Network
    private let peerPortField    = PaneField()
    private let portPollURLField = PaneField(placeholder: "https://host/port.txt", wide: true)
    private let portPollResult   = NSTextField(labelWithString: "")
    private let upnpCheck        = PaneCheck()
    private let pexCheck         = PaneCheck()
    private let dhtCheck         = PaneCheck()
    private let lpdCheck         = PaneCheck()

    // MARK: - Build

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        let C = S.Settings.Connection.self
        let D = S.Settings.Download.self
        let Sp = S.Settings.Speed.self
        let Q = S.Settings.Queue.self
        let N = S.Settings.Network.self

        // Connection
        stack.addArrangedSubview(sectionHeader(S.Settings.Section.connection))
        stack.addArrangedSubview(formGrid([
            (C.host,      hostField,    C.hostTip),
            (C.rpcPort,   rpcPortField, C.rpcPortTip),
            (C.path,      pathField,    C.pathTip),
            (C.username,  userField,    C.usernameTip),
            (C.password,  passField,    C.passwordTip),
            (C.useHTTPS,  sslCheck,     C.useHTTPSTip),
            (C.poll,      pollField,    C.pollTip),
        ]))
        stack.addArrangedSubview(actionRow(testButton))
        stack.addArrangedSubview(actionRow(testResult))
        stack.addArrangedSubview(sectionSpacer())

        // Download
        stack.addArrangedSubview(sectionHeader(S.Settings.Section.download))
        stack.addArrangedSubview(formGrid([
            (D.directory,  dlDirField,  D.directoryTip),
            (D.incomplete, incompField, D.incompleteTip),
            (D.start,      startCheck,  D.startTip),
            (D.trash,      trashCheck,  D.trashTip),
            (D.appendPart, renameCheck, D.appendPartTip),
        ]))
        stack.addArrangedSubview(sectionSpacer())

        // Speed Limits
        stack.addArrangedSubview(sectionHeader(S.Settings.Section.speed))
        stack.addArrangedSubview(formGrid([
            (Sp.download,    dlLimitField, Sp.downloadTip),
            (Sp.upload,      ulLimitField, Sp.uploadTip),
            (Sp.altDownload, altDlField,   Sp.altDownloadTip),
            (Sp.altUpload,   altUlField,   Sp.altUploadTip),
        ]))
        stack.addArrangedSubview(sectionSpacer())

        // Queue
        stack.addArrangedSubview(sectionHeader(S.Settings.Section.queue))
        stack.addArrangedSubview(formGrid([
            (Q.maxDownloads, dlQueueField,   Q.maxDownloadsTip),
            (Q.maxSeeds,     seedQueueField, Q.maxSeedsTip),
            (Q.ratioLimit,   seedRatioField, Q.ratioLimitTip),
            (Q.idleLimit,    idleField,      Q.idleLimitTip),
        ]))
        stack.addArrangedSubview(sectionSpacer())

        // Network
        stack.addArrangedSubview(sectionHeader(S.Settings.Section.network))
        stack.addArrangedSubview(formGrid([
            (N.peerPort,    peerPortField,    N.peerPortTip),
            (N.autoPortURL, portPollURLField, N.autoPortURLTip),
            ("",            portPollResult,   nil),
            (N.upnp,        upnpCheck,        N.upnpTip),
            (N.pex,         pexCheck,         N.pexTip),
            (N.dht,         dhtCheck,         N.dhtTip),
            (N.lpd,         lpdCheck,         N.lpdTip),
        ]))
        stack.addArrangedSubview(sectionSpacer())

        // Scroll
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let docView = NSView()
        docView.translatesAutoresizingMaskIntoConstraints = false
        docView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: docView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: docView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: docView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: docView.bottomAnchor),
        ])
        scroll.documentView = docView
        NSLayoutConstraint.activate([
            docView.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])

        let outer = NSView()
        outer.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: outer.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: outer.bottomAnchor),
            outer.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ])
        view = outer

        wireTargets()
    }

    private func wireTargets() {
        testButton.bezelStyle = .rounded

        testButton.target = self
        testButton.action = #selector(testConnection)

        for lbl in [testResult, portPollResult] {
            lbl.font = .systemFont(ofSize: paneFont.pointSize)
            lbl.textColor = Theme.comment
            lbl.translatesAutoresizingMaskIntoConstraints = false
        }

        let connFields: [NSControl] = [hostField, rpcPortField, pathField, sslCheck,
                                        userField, passField, pollField]
        connFields.forEach { $0.target = self; $0.action = #selector(saveConnection) }

        let dlFields: [NSControl] = [dlDirField, incompField, startCheck, trashCheck, renameCheck]
        dlFields.forEach { $0.target = self; $0.action = #selector(applyGeneral) }

        let speedFields: [NSControl] = [dlLimitField, ulLimitField, altDlField, altUlField]
        speedFields.forEach { $0.target = self; $0.action = #selector(applySpeed) }

        let queueFields: [NSControl] = [dlQueueField, seedQueueField, seedRatioField, idleField]
        queueFields.forEach { $0.target = self; $0.action = #selector(applyQueue) }

        let netFields: [NSControl] = [peerPortField, upnpCheck, pexCheck, dhtCheck, lpdCheck]
        netFields.forEach { $0.target = self; $0.action = #selector(applyNetwork) }

        portPollURLField.target = self
        portPollURLField.action = #selector(savePortPollURL)
    }

    // MARK: - isEditing

    var isEditing: Bool {
        let fields: [NSTextField] = [
            hostField, rpcPortField, pathField, userField, passField, pollField,
            dlDirField, incompField,
            dlLimitField, ulLimitField, altDlField, altUlField,
            dlQueueField, seedQueueField, seedRatioField, idleField,
            peerPortField, portPollURLField,
        ]
        return fields.contains { $0.currentEditor() != nil }
    }

    // MARK: - Load

    func reload() {
        let cfg = ServerConfig.load()
        hostField.stringValue    = cfg.host
        rpcPortField.stringValue = "\(cfg.port)"
        pathField.stringValue    = cfg.path
        sslCheck.state           = cfg.useHTTPS ? .on : .off
        userField.stringValue    = cfg.username
        passField.stringValue    = cfg.password
        pollField.stringValue    = "\(cfg.pollInterval)"

        guard let s = appService.session else { return }

        dlDirField.stringValue  = s.downloadDir
        incompField.stringValue = s.incompleteDirEnabled ? s.incompleteDir : ""

        startCheck.state  = s.startAddedTorrents ? .on : .off
        trashCheck.state  = s.trashOriginalTorrentFiles ? .on : .off
        renameCheck.state = s.renamePartialFiles ? .on : .off

        dlLimitField.stringValue   = s.speedLimitDownEnabled ? "\(s.speedLimitDown)" : ""
        ulLimitField.stringValue   = s.speedLimitUpEnabled   ? "\(s.speedLimitUp)"   : ""
        altDlField.stringValue     = "\(s.altSpeedDown)"
        altUlField.stringValue     = "\(s.altSpeedUp)"

        dlQueueField.stringValue   = s.downloadQueueEnabled    ? "\(s.downloadQueueSize)"                   : ""
        seedQueueField.stringValue = s.seedQueueEnabled        ? "\(s.seedQueueSize)"                       : ""
        seedRatioField.stringValue = s.seedRatioLimited        ? String(format: "%.2f", s.seedRatioLimit)   : ""
        idleField.stringValue      = s.idleSeedingLimitEnabled ? "\(s.idleSeedingLimit)"                    : ""

        peerPortField.stringValue = "\(s.peerPort)"
        upnpCheck.state = s.portForwardingEnabled ? .on : .off
        pexCheck.state  = s.pexEnabled ? .on : .off
        dhtCheck.state  = s.dhtEnabled ? .on : .off
        lpdCheck.state  = s.lpdEnabled ? .on : .off

        portPollURLField.stringValue = ServerConfig.load().portPollURL

        let last = appService.lastPortSyncResult
        if !last.isEmpty {
            portPollResult.stringValue = last
            portPollResult.textColor = last.hasPrefix("✓") ? Theme.green : Theme.red
        }
    }

    // MARK: - Apply

    @objc private func saveConnection() {
        var cfg = ServerConfig()
        cfg.host         = hostField.stringValue
        cfg.port         = Int(rpcPortField.stringValue) ?? 9091
        cfg.path         = pathField.stringValue
        cfg.useHTTPS     = sslCheck.state == .on
        cfg.username     = userField.stringValue
        cfg.password     = passField.stringValue
        cfg.pollInterval = Double(pollField.stringValue) ?? 2.0
        cfg.save()
        appService.configure(
            host: cfg.host, port: cfg.port, path: cfg.path, useHTTPS: cfg.useHTTPS,
            username: cfg.username.isEmpty ? nil : cfg.username,
            password: cfg.password.isEmpty ? nil : cfg.password
        )
        appService.startPolling(interval: .seconds(cfg.pollInterval))
    }

    @objc private func testConnection() {
        testResult.stringValue = "Connecting…"
        testResult.textColor = Theme.comment
        let host = hostField.stringValue
        let port = Int(rpcPortField.stringValue) ?? 9091
        let path = pathField.stringValue
        let ssl  = sslCheck.state == .on
        let user = userField.stringValue.isEmpty ? nil : userField.stringValue
        let pass = passField.stringValue.isEmpty ? nil : passField.stringValue
        Task {
            let transport = HTTPTransport(host: host, port: port, path: path,
                                         useHTTPS: ssl, username: user, password: pass)
            let rpc = RPCSession(transport: transport)
            do {
                let s = try await rpc.fetchSession()
                testResult.stringValue = "✓ Transmission \(s.version)"
                testResult.textColor = Theme.green
            } catch {
                testResult.stringValue = "✗ \(error.localizedDescription)"
                testResult.textColor = Theme.red
            }
        }
    }

    @objc private func applyGeneral() {
        var p = SessionPatch()
        p.downloadDir = dlDirField.stringValue
        let incomp = incompField.stringValue.trimmingCharacters(in: .whitespaces)
        p.incompleteDirEnabled = !incomp.isEmpty
        if !incomp.isEmpty { p.incompleteDir = incomp }
        p.startAddedTorrents        = startCheck.state == .on
        p.trashOriginalTorrentFiles = trashCheck.state == .on
        p.renamePartialFiles        = renameCheck.state == .on
        sendSessionPatch(p)
    }

    @objc private func applySpeed() {
        var p = SessionPatch()
        let dl = dlLimitField.stringValue.trimmingCharacters(in: .whitespaces)
        p.speedLimitDownEnabled = !dl.isEmpty
        p.speedLimitDown        = Int(dl) ?? 0
        let ul = ulLimitField.stringValue.trimmingCharacters(in: .whitespaces)
        p.speedLimitUpEnabled   = !ul.isEmpty
        p.speedLimitUp          = Int(ul) ?? 0
        p.altSpeedDown = Int(altDlField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        p.altSpeedUp   = Int(altUlField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        sendSessionPatch(p)
    }

    @objc private func applyQueue() {
        var p = SessionPatch()
        let dlq = dlQueueField.stringValue.trimmingCharacters(in: .whitespaces)
        p.downloadQueueEnabled = !dlq.isEmpty
        p.downloadQueueSize    = Int(dlq) ?? 0
        let sq = seedQueueField.stringValue.trimmingCharacters(in: .whitespaces)
        p.seedQueueEnabled = !sq.isEmpty
        p.seedQueueSize    = Int(sq) ?? 0
        let ratio = seedRatioField.stringValue.trimmingCharacters(in: .whitespaces)
        p.seedRatioLimited = !ratio.isEmpty
        p.seedRatioLimit   = Double(ratio) ?? 0
        let idle = idleField.stringValue.trimmingCharacters(in: .whitespaces)
        p.idleSeedingLimitEnabled = !idle.isEmpty
        p.idleSeedingLimit        = Int(idle) ?? 0
        sendSessionPatch(p)
    }

    @objc private func applyNetwork() {
        var p = SessionPatch()
        p.peerPort              = Int(peerPortField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 51413
        p.portForwardingEnabled = upnpCheck.state == .on
        p.pexEnabled            = pexCheck.state == .on
        p.dhtEnabled            = dhtCheck.state == .on
        p.lpdEnabled            = lpdCheck.state == .on
        sendSessionPatch(p)
    }

    @objc private func savePortPollURL() {
        var cfg = ServerConfig.load()
        let url = portPollURLField.stringValue.trimmingCharacters(in: .whitespaces)
        cfg.portPollURL = url
        cfg.save()

        portPollResult.stringValue = ""
        guard !url.isEmpty else { return }

        portPollResult.stringValue = "Fetching…"
        portPollResult.textColor = Theme.comment

        Task {
            let msg = await appService.syncPortFromURL(url)
            portPollResult.stringValue = msg
            portPollResult.textColor = msg.hasPrefix("✓") ? Theme.green : Theme.red
        }
    }

    private func sendSessionPatch(_ patch: SessionPatch) {
        Task {
            try? await appService.rpcSession?.setSession(patch)
            await appService.refresh()
        }
    }

    // MARK: - Layout helpers

    private var paneFont: NSFont { .systemFont(ofSize: 12) }

    private func sectionHeader(_ title: String) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = Theme.comment
        label.translatesAutoresizingMaskIntoConstraints = false

        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        container.addSubview(sep)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            sep.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            sep.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 3),
            sep.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
        return container
    }

    private func sectionSpacer() -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: 2),
        ])
        return v
    }

    /// Rows: (label, control, tooltip). Pass nil tooltip to skip.
    private func formGrid(_ rows: [(String, NSView, String?)]) -> NSView {
        let grid = NSGridView()
        grid.rowSpacing = 4
        grid.columnSpacing = 8
        grid.translatesAutoresizingMaskIntoConstraints = false

        for (labelText, control, tip) in rows {
            let lbl = NSTextField(labelWithString: labelText.isEmpty ? "" : "\(labelText):")
            lbl.alignment = .right
            lbl.font = paneFont
            lbl.textColor = Theme.comment
            lbl.translatesAutoresizingMaskIntoConstraints = false

            if let tip {
                lbl.toolTip = tip
                control.toolTip = tip
            }

            // Apply consistent font to editable fields
            if let tf = control as? NSTextField, tf.isEditable {
                tf.font = paneFont
            } else if let btn = control as? NSButton {
                btn.font = paneFont
            }

            grid.addRow(with: [lbl, control])
        }

        if grid.numberOfColumns >= 2 {
            grid.column(at: 0).width = 120
            grid.column(at: 0).xPlacement = .trailing
        }

        let wrap = NSView()
        wrap.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            grid.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
            grid.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 3),
            grid.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -3),
        ])
        return wrap
    }

    private func actionRow(_ view: NSView) -> NSView {
        view.translatesAutoresizingMaskIntoConstraints = false
        let wrap = NSView()
        wrap.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 140),
            view.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 2),
            view.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -2),
        ])
        return wrap
    }
}

// MARK: - PaneField

private final class PaneField: NSTextField {
    init(placeholder: String? = nil, wide: Bool = false) {
        super.init(frame: .zero)
        bezelStyle = .roundedBezel
        font = .systemFont(ofSize: 12)
        translatesAutoresizingMaskIntoConstraints = false
        if let ph = placeholder { placeholderString = ph }
        if wide {
            setContentHuggingPriority(.defaultLow, for: .horizontal)
            NSLayoutConstraint.activate([
                widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            ])
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard let editor = currentEditor() as? NSTextView,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
        else { return super.performKeyEquivalent(with: event) }
        switch event.charactersIgnoringModifiers {
        case "a": editor.selectAll(nil);  return true
        case "v": editor.paste(nil);      return true
        case "c": editor.copy(nil);       return true
        case "x": editor.cut(nil);        return true
        case "z":
            if event.modifierFlags.contains(.shift) { editor.undoManager?.redo() }
            else { editor.undoManager?.undo() }
            return true
        default:  return super.performKeyEquivalent(with: event)
        }
    }
}

// MARK: - PaneSecure

private final class PaneSecure: NSSecureTextField {
    init() {
        super.init(frame: .zero)
        bezelStyle = .roundedBezel
        font = .systemFont(ofSize: 12)
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - PaneCheck

private final class PaneCheck: NSButton {
    init() {
        super.init(frame: .zero)
        title = ""
        setButtonType(.switch)
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
