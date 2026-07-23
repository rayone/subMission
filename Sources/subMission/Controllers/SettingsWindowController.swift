import AppKit
import TransmissionRPC

private var portDelegateKey: UInt8 = 0

private final class PortFieldDelegate: NSObject, NSTextFieldDelegate {
    let onCommit: () -> Void
    init(onCommit: @escaping () -> Void) { self.onCommit = onCommit }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        let digits = field.stringValue.filter { $0.isNumber }
        field.stringValue = digits.isEmpty ? "51413" : digits
        onCommit()
    }
}

final class SettingsWindowController: NSWindowController, NSToolbarDelegate {
    let appService: AppService

    private var tabView: NSTabView!

    // Tabs
    private var connectionTab: ConnectionSettingsTab!
    private var generalTab:    GeneralSettingsTab!
    private var speedTab:      SpeedSettingsTab!
    private var queueTab:      QueueSettingsTab!
    private var networkTab:    NetworkSettingsTab!
    private var scriptingTab:  ScriptingSettingsTab!

    private init(appService: AppService) {
        self.appService = appService
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = S.Settings.title
        super.init(window: window)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        guard let window else { return }

        connectionTab = ConnectionSettingsTab(appService: appService)
        generalTab    = GeneralSettingsTab(appService: appService)
        speedTab      = SpeedSettingsTab(appService: appService)
        queueTab      = QueueSettingsTab(appService: appService)
        networkTab    = NetworkSettingsTab(appService: appService)
        scriptingTab  = ScriptingSettingsTab(appService: appService)

        tabView = NSTabView()
        tabView.tabViewType = .topTabsBezelBorder
        tabView.translatesAutoresizingMaskIntoConstraints = false

        let tabs: [(String, NSViewController)] = [
            (S.Settings.Tab.connection, connectionTab), (S.Settings.Tab.general, generalTab),
            (S.Settings.Tab.speed, speedTab), (S.Settings.Tab.queue, queueTab),
            (S.Settings.Tab.network, networkTab), (S.Settings.Tab.scripting, scriptingTab)
        ]
        for (title, vc) in tabs {
            let item = NSTabViewItem(viewController: vc)
            item.label = title
            tabView.addTabViewItem(item)
        }

        window.contentView?.addSubview(tabView)
        if let cv = window.contentView {
            NSLayoutConstraint.activate([
                tabView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                tabView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
                tabView.topAnchor.constraint(equalTo: cv.topAnchor),
                tabView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            ])
        }
    }

    static var shared: SettingsWindowController?

    static func showWindow(_ sender: Any?, appService: AppService) {
        if shared == nil {
            shared = SettingsWindowController(appService: appService)
        }
        shared?.showWindow(sender)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        // Reload from live session data
        if let session = appService.session {
            generalTab.load(session)
            speedTab.load(session)
            queueTab.load(session)
            networkTab.load(session)
            scriptingTab.load(session)
        }
        connectionTab.loadConfig()
    }
}

// MARK: - Connection Tab

final class ConnectionSettingsTab: NSViewController {
    let appService: AppService
    private let hostField   = NSTextField()
    private let portField   = NSTextField()
    private let pathField   = NSTextField()
    private let sslCheck    = NSButton(checkboxWithTitle: S.Settings.Connection.useHTTPS, target: nil, action: nil)
    private let userField   = NSTextField()
    private let passField   = NSSecureTextField()
    private let pollField   = NSTextField()
    private let testButton  = NSButton(title: S.Settings.Connection.testButton, target: nil, action: nil)
    private let testResult  = NSTextField(labelWithString: "")

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let v = buildFormView([
            (S.Settings.Connection.hostLabel,     hostField),
            (S.Settings.Connection.portLabel,     portField),
            (S.Settings.Connection.pathLabel,     pathField),
            ("",                                  sslCheck),
            (S.Settings.Connection.usernameLabel, userField),
            (S.Settings.Connection.passwordLabel, passField),
            (S.Settings.Connection.pollLabel,     pollField),
        ])
        testButton.bezelStyle = .rounded
        testButton.target = self
        testButton.action = #selector(testConnection)
        testResult.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        testResult.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [v, testButton, testResult])
        stack.orientation = .vertical; stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        let outer = NSView()
        outer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 16),
            stack.topAnchor.constraint(equalTo: outer.topAnchor, constant: 16),
        ])
        view = outer
    }

    func loadConfig() {
        let cfg = ServerConfig.load()
        hostField.stringValue = cfg.host
        portField.stringValue = "\(cfg.port)"
        pathField.stringValue = cfg.path
        sslCheck.state = cfg.useHTTPS ? .on : .off
        userField.stringValue = cfg.username
        passField.stringValue = cfg.password
        pollField.stringValue = "\(cfg.pollInterval)"
    }

    @IBAction private func saveAndApply(_ sender: Any?) {
        var cfg = ServerConfig()
        cfg.host = hostField.stringValue
        cfg.port = Int(portField.stringValue) ?? 9091
        cfg.path = pathField.stringValue
        cfg.useHTTPS = sslCheck.state == .on
        cfg.username = userField.stringValue
        cfg.password = passField.stringValue
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
        testResult.stringValue = S.Settings.Connection.connecting
        testResult.textColor = .secondaryLabelColor
        let host  = hostField.stringValue
        let port  = Int(portField.stringValue) ?? 9091
        let path  = pathField.stringValue
        let ssl   = sslCheck.state == .on
        let user  = userField.stringValue.isEmpty ? nil : userField.stringValue
        let pass  = passField.stringValue.isEmpty ? nil : passField.stringValue
        Task {
            let transport = HTTPTransport(host: host, port: port, path: path,
                                         useHTTPS: ssl, username: user, password: pass)
            let session = RPCSession(transport: transport)
            do {
                let s = try await session.fetchSession()
                testResult.stringValue = S.Settings.Connection.connected(version: s.version)
                testResult.textColor = .systemGreen
            } catch {
                testResult.stringValue = S.Settings.Connection.failed(reason: error.localizedDescription)
                testResult.textColor = .systemRed
            }
        }
    }
}

// MARK: - General Tab

final class GeneralSettingsTab: NSViewController {
    let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private let dlDirField    = NSTextField()
    private let incompCheck   = NSButton(checkboxWithTitle: S.Settings.Download.incompCheck,  target: nil, action: nil)
    private let incompField   = NSTextField()
    private let startCheck    = NSButton(checkboxWithTitle: S.Settings.Download.startCheck,   target: nil, action: nil)
    private let trashCheck    = NSButton(checkboxWithTitle: S.Settings.Download.trashCheck,   target: nil, action: nil)
    private let renameCheck   = NSButton(checkboxWithTitle: S.Settings.Download.renameCheck,  target: nil, action: nil)
    private let trackersField = NSTextField()

    override func loadView() {
        view = buildFormView([
            (S.Settings.Download.dlDirLabel,    dlDirField),
            ("",                                incompCheck),
            (S.Settings.Download.incompDirLabel, incompField),
            ("",                                startCheck),
            ("",                                trashCheck),
            ("",                                renameCheck),
            (S.Settings.Download.trackersLabel, trackersField),
        ])
        [dlDirField, incompField, trackersField].forEach { $0.target = self; $0.action = #selector(apply) }
        [incompCheck, startCheck, trashCheck, renameCheck].forEach { $0.target = self; $0.action = #selector(apply) }
    }

    func load(_ s: Session) {
        dlDirField.stringValue  = s.downloadDir
        incompCheck.state       = s.incompleteDirEnabled ? .on : .off
        incompField.stringValue = s.incompleteDir
        startCheck.state        = s.startAddedTorrents ? .on : .off
        trashCheck.state        = s.trashOriginalTorrentFiles ? .on : .off
        renameCheck.state       = s.renamePartialFiles ? .on : .off
        trackersField.stringValue = s.defaultTrackers
    }

    @objc private func apply() {
        var p = SessionPatch()
        p.downloadDir                = dlDirField.stringValue
        p.incompleteDirEnabled       = incompCheck.state == .on
        p.incompleteDir              = incompField.stringValue
        p.startAddedTorrents         = startCheck.state == .on
        p.trashOriginalTorrentFiles  = trashCheck.state == .on
        p.renamePartialFiles         = renameCheck.state == .on
        p.defaultTrackers            = trackersField.stringValue
        sendPatch(p)
    }
}

// MARK: - Speed Tab

final class SpeedSettingsTab: NSViewController {
    let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private let dlLimitCheck  = NSButton(checkboxWithTitle: S.Settings.Speed.dlLimitCheck,  target: nil, action: nil)
    private let dlLimitField  = NSTextField()
    private let ulLimitCheck  = NSButton(checkboxWithTitle: S.Settings.Speed.ulLimitCheck,  target: nil, action: nil)
    private let ulLimitField  = NSTextField()
    private let altDlField    = NSTextField()
    private let altUlField    = NSTextField()
    private let altSchedCheck = NSButton(checkboxWithTitle: S.Settings.Speed.altSchedCheck, target: nil, action: nil)
    private let altBeginField = NSTextField()
    private let altEndField   = NSTextField()

    override func loadView() {
        view = buildFormView([
            ("",                       dlLimitCheck),
            (S.Settings.Speed.dlKbps,  dlLimitField),
            ("",                       ulLimitCheck),
            (S.Settings.Speed.ulKbps,  ulLimitField),
            (S.Settings.Speed.altDlKbps, altDlField),
            (S.Settings.Speed.altUlKbps, altUlField),
            ("",                       altSchedCheck),
            (S.Settings.Speed.altBegin, altBeginField),
            (S.Settings.Speed.altEnd,   altEndField),
        ])
        [dlLimitCheck, ulLimitCheck, altSchedCheck].forEach { $0.target = self; $0.action = #selector(apply) }
        [dlLimitField, ulLimitField, altDlField, altUlField, altBeginField, altEndField].forEach {
            $0.target = self; $0.action = #selector(apply)
        }
    }

    func load(_ s: Session) {
        dlLimitCheck.state   = s.speedLimitDownEnabled ? .on : .off
        dlLimitField.stringValue = "\(s.speedLimitDown)"
        ulLimitCheck.state   = s.speedLimitUpEnabled ? .on : .off
        ulLimitField.stringValue = "\(s.speedLimitUp)"
        altDlField.stringValue   = "\(s.altSpeedDown)"
        altUlField.stringValue   = "\(s.altSpeedUp)"
        altSchedCheck.state  = s.altSpeedTimeEnabled ? .on : .off
        altBeginField.stringValue = "\(s.altSpeedTimeBegin)"
        altEndField.stringValue   = "\(s.altSpeedTimeEnd)"
        updateVisibility()
    }

    @objc private func apply() {
        updateVisibility()
        var p = SessionPatch()
        p.speedLimitDownEnabled = dlLimitCheck.state == .on
        p.speedLimitDown        = Int(dlLimitField.stringValue) ?? 0
        p.speedLimitUpEnabled   = ulLimitCheck.state == .on
        p.speedLimitUp          = Int(ulLimitField.stringValue) ?? 0
        p.altSpeedDown          = Int(altDlField.stringValue) ?? 0
        p.altSpeedUp            = Int(altUlField.stringValue) ?? 0
        p.altSpeedTimeEnabled   = altSchedCheck.state == .on
        p.altSpeedTimeBegin     = Int(altBeginField.stringValue) ?? 0
        p.altSpeedTimeEnd       = Int(altEndField.stringValue) ?? 0
        sendPatch(p)
    }

    private func updateVisibility() {
        dlLimitField.isHidden  = dlLimitCheck.state == .off
        ulLimitField.isHidden  = ulLimitCheck.state == .off
        altBeginField.isHidden = altSchedCheck.state == .off
        altEndField.isHidden   = altSchedCheck.state == .off
    }
}

// MARK: - Queue Tab

final class QueueSettingsTab: NSViewController {
    let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private let dlQueueCheck = NSButton(checkboxWithTitle: S.Settings.Queue.dlQueueCheck,   target: nil, action: nil)
    private let dlQueueField = NSTextField()
    private let seedQueueCheck = NSButton(checkboxWithTitle: S.Settings.Queue.seedQueueCheck, target: nil, action: nil)
    private let seedQueueField = NSTextField()
    private let stalledCheck = NSButton(checkboxWithTitle: S.Settings.Queue.stalledCheck,   target: nil, action: nil)
    private let stalledField = NSTextField()
    private let seedRatioCheck = NSButton(checkboxWithTitle: S.Settings.Queue.seedRatioCheck, target: nil, action: nil)
    private let seedRatioField = NSTextField()
    private let idleLimitCheck = NSButton(checkboxWithTitle: S.Settings.Queue.idleLimitCheck, target: nil, action: nil)
    private let idleLimitField = NSTextField()

    override func loadView() {
        view = buildFormView([
            ("", dlQueueCheck),   (S.Settings.Queue.dlQueueLabel,    dlQueueField),
            ("", seedQueueCheck), (S.Settings.Queue.seedQueueLabel,  seedQueueField),
            ("", stalledCheck),   (S.Settings.Queue.stalledLabel,    stalledField),
            ("", seedRatioCheck), (S.Settings.Queue.ratioLimitLabel, seedRatioField),
            ("", idleLimitCheck), (S.Settings.Queue.idleLimitLabel,  idleLimitField),
        ])
        [dlQueueCheck, seedQueueCheck, stalledCheck, seedRatioCheck, idleLimitCheck].forEach {
            $0.target = self; $0.action = #selector(apply)
        }
        [dlQueueField, seedQueueField, stalledField, seedRatioField, idleLimitField].forEach {
            $0.target = self; $0.action = #selector(apply)
        }
    }

    func load(_ s: Session) {
        dlQueueCheck.state   = s.downloadQueueEnabled ? .on : .off
        dlQueueField.stringValue = "\(s.downloadQueueSize)"
        seedQueueCheck.state = s.seedQueueEnabled ? .on : .off
        seedQueueField.stringValue = "\(s.seedQueueSize)"
        stalledCheck.state   = s.queueStalledEnabled ? .on : .off
        stalledField.stringValue = "\(s.queueStalledMinutes)"
        seedRatioCheck.state = s.seedRatioLimited ? .on : .off
        seedRatioField.stringValue = String(format: "%.2f", s.seedRatioLimit)
        idleLimitCheck.state = s.idleSeedingLimitEnabled ? .on : .off
        idleLimitField.stringValue = "\(s.idleSeedingLimit)"
        updateVisibility()
    }

    @objc private func apply() {
        updateVisibility()
        var p = SessionPatch()
        p.downloadQueueEnabled   = dlQueueCheck.state == .on
        p.downloadQueueSize      = Int(dlQueueField.stringValue) ?? 0
        p.seedQueueEnabled       = seedQueueCheck.state == .on
        p.seedQueueSize          = Int(seedQueueField.stringValue) ?? 0
        p.queueStalledEnabled    = stalledCheck.state == .on
        p.queueStalledMinutes    = Int(stalledField.stringValue) ?? 0
        p.seedRatioLimited       = seedRatioCheck.state == .on
        p.seedRatioLimit         = Double(seedRatioField.stringValue) ?? 0
        p.idleSeedingLimitEnabled = idleLimitCheck.state == .on
        p.idleSeedingLimit       = Int(idleLimitField.stringValue) ?? 0
        sendPatch(p)
    }

    private func updateVisibility() {
        dlQueueField.isHidden    = dlQueueCheck.state == .off
        seedQueueField.isHidden  = seedQueueCheck.state == .off
        stalledField.isHidden    = stalledCheck.state == .off
        seedRatioField.isHidden  = seedRatioCheck.state == .off
        idleLimitField.isHidden  = idleLimitCheck.state == .off
    }
}

// MARK: - Network Tab

final class NetworkSettingsTab: NSViewController {
    let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private let portField          = NSTextField()
    private let randomPortCheck    = NSButton(checkboxWithTitle: S.Settings.Network.randomPortCheck, target: nil, action: nil)
    private let upnpCheck          = NSButton(checkboxWithTitle: S.Settings.Network.upnpCheck,        target: nil, action: nil)
    private let peerLimitGlobal    = NSTextField()
    private let peerLimitPerTorrent = NSTextField()
    private let encryptPopup       = NSPopUpButton()
    private let pexCheck           = NSButton(checkboxWithTitle: S.Settings.Network.pexCheck,         target: nil, action: nil)
    private let dhtCheck           = NSButton(checkboxWithTitle: S.Settings.Network.dhtCheck,         target: nil, action: nil)
    private let lpdCheck           = NSButton(checkboxWithTitle: S.Settings.Network.lpdCheck,         target: nil, action: nil)
    private let blocklistCheck     = NSButton(checkboxWithTitle: S.Settings.Network.blocklistCheck,   target: nil, action: nil)
    private let blocklistField     = NSTextField()
    private let testPortButton     = NSButton(title: S.Settings.Network.testPortButton,   target: nil, action: nil)
    private let testPortResult     = NSTextField(labelWithString: "")
    private let updateBLButton     = NSButton(title: S.Settings.Network.updateBLButton,   target: nil, action: nil)

    override func loadView() {
        encryptPopup.removeAllItems()
        encryptPopup.addItems(withTitles: [S.Settings.Network.encRequired, S.Settings.Network.encPreferred, S.Settings.Network.encAllowed])

        let formView = buildFormView([
            (S.Settings.Network.portLabel,           portField),
            ("",                                     randomPortCheck),
            ("",                                     upnpCheck),
            (S.Settings.Network.peerLimitGlobal,     peerLimitGlobal),
            (S.Settings.Network.peerLimitPerTorrent, peerLimitPerTorrent),
            (S.Settings.Network.encryption,          encryptPopup),
            ("",                                     pexCheck),
            ("",                                     dhtCheck),
            ("",                                     lpdCheck),
            ("",                                     blocklistCheck),
            (S.Settings.Network.blocklistURL,        blocklistField),
        ])

        testPortButton.bezelStyle = .rounded
        testPortButton.target = self; testPortButton.action = #selector(testPort)
        testPortResult.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        testPortResult.textColor = .secondaryLabelColor
        updateBLButton.bezelStyle = .rounded
        updateBLButton.target = self; updateBLButton.action = #selector(updateBlocklist)

        let stack = NSStackView(views: [formView, testPortButton, testPortResult, updateBLButton])
        stack.orientation = .vertical; stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        let outer = NSView()
        outer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 16),
            stack.topAnchor.constraint(equalTo: outer.topAnchor, constant: 16),
        ])
        view = outer

        [randomPortCheck, upnpCheck, pexCheck, dhtCheck, lpdCheck, blocklistCheck].forEach {
            $0.target = self; $0.action = #selector(apply)
        }
        encryptPopup.target = self; encryptPopup.action = #selector(apply)
        
        let portDelegate = PortFieldDelegate(onCommit: { [weak self] in
            self?.apply()
        })
        portField.delegate = portDelegate
        objc_setAssociatedObject(portField, &portDelegateKey, portDelegate, .OBJC_ASSOCIATION_RETAIN)
        
        [blocklistField, peerLimitGlobal, peerLimitPerTorrent].forEach {
            $0.target = self; $0.action = #selector(apply)
        }
    }

    func load(_ s: Session) {
        portField.stringValue           = "\(s.peerPort)"
        randomPortCheck.state           = s.peerPortRandomOnStart ? .on : .off
        upnpCheck.state                 = s.portForwardingEnabled ? .on : .off
        peerLimitGlobal.stringValue     = "\(s.peerLimitGlobal)"
        peerLimitPerTorrent.stringValue = "\(s.peerLimitPerTorrent)"
        let encIdx: Int
        switch s.encryption {
        case .required:  encIdx = 0
        case .preferred: encIdx = 1
        case .allowed:   encIdx = 2
        }
        encryptPopup.selectItem(at: encIdx)
        pexCheck.state             = s.pexEnabled ? .on : .off
        dhtCheck.state             = s.dhtEnabled ? .on : .off
        lpdCheck.state             = s.lpdEnabled ? .on : .off
        blocklistCheck.state       = s.blocklistEnabled ? .on : .off
        blocklistField.stringValue = s.blocklistUrl
    }

    @objc private func apply() {
        var p = SessionPatch()
        p.peerPort                = Int(portField.stringValue) ?? 51413
        p.peerPortRandomOnStart   = randomPortCheck.state == .on
        p.portForwardingEnabled   = upnpCheck.state == .on
        p.peerLimitGlobal         = Int(peerLimitGlobal.stringValue) ?? 200
        p.peerLimitPerTorrent     = Int(peerLimitPerTorrent.stringValue) ?? 50
        let encVals = ["required", "preferred", "tolerated"]
        p.encryption              = encVals[min(encryptPopup.indexOfSelectedItem, 2)]
        p.pexEnabled              = pexCheck.state == .on
        p.dhtEnabled              = dhtCheck.state == .on
        p.lpdEnabled              = lpdCheck.state == .on
        p.blocklistEnabled        = blocklistCheck.state == .on
        p.blocklistUrl            = blocklistField.stringValue
        sendPatch(p)
    }

    @objc private func testPort() {
        testPortResult.stringValue = "Testing…"; testPortResult.textColor = .secondaryLabelColor
        Task {
            do {
                let result = try await appService.rpcSession?.portTest()
                let open = result?.isOpen ?? false
                testPortResult.stringValue = open ? S.Settings.Network.portOpen() : S.Settings.Network.portClosed()
                testPortResult.textColor   = open ? .systemGreen : .systemRed
            } catch {
                testPortResult.stringValue = S.Settings.Network.portFailed(reason: error.localizedDescription)
                testPortResult.textColor   = .systemRed
            }
        }
    }

    @objc private func updateBlocklist() {
        Task { try? await appService.rpcSession?.updateBlocklist() }
    }
}

// MARK: - Scripting Tab

final class ScriptingSettingsTab: NSViewController {
    let appService: AppService

    init(appService: AppService) {
        self.appService = appService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    // Torrent added
    private let addedCheck = NSButton(checkboxWithTitle: S.Settings.Scripting.addedCheck,   target: nil, action: nil)
    private let addedField = NSTextField()
    private let addedBrowse = NSButton(title: S.Settings.Scripting.browseButton, target: nil, action: nil)
    // Download complete
    private let doneCheck = NSButton(checkboxWithTitle: S.Settings.Scripting.doneCheck,    target: nil, action: nil)
    private let doneField = NSTextField()
    private let doneBrowse = NSButton(title: S.Settings.Scripting.browseButton, target: nil, action: nil)
    // Seeding complete
    private let seedingCheck = NSButton(checkboxWithTitle: S.Settings.Scripting.seedingCheck, target: nil, action: nil)
    private let seedingField = NSTextField()
    private let seedingBrowse = NSButton(title: S.Settings.Scripting.browseButton, target: nil, action: nil)

    override func loadView() {
        [addedBrowse, doneBrowse, seedingBrowse].forEach { b in
            b.bezelStyle = .rounded
        }
        addedBrowse.target = self;   addedBrowse.action   = #selector(browseAdded)
        doneBrowse.target = self;    doneBrowse.action    = #selector(browseDone)
        seedingBrowse.target = self; seedingBrowse.action = #selector(browseSeeding)

        [addedCheck, doneCheck, seedingCheck].forEach { $0.target = self; $0.action = #selector(apply) }
        [addedField, doneField, seedingField].forEach  { $0.target = self; $0.action = #selector(apply) }

        func hookRow(_ check: NSButton, _ field: NSTextField, _ browse: NSButton) -> NSView {
            let row = NSStackView(views: [field, browse])
            row.orientation = .horizontal; row.spacing = 6
            let stack = NSStackView(views: [check, row])
            stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            field.setContentHuggingPriority(.defaultLow, for: .horizontal)
            NSLayoutConstraint.activate([
                row.widthAnchor.constraint(equalToConstant: 360),
            ])
            return stack
        }

        let mainStack = NSStackView(views: [
            hookRow(addedCheck,   addedField,   addedBrowse),
            hookRow(doneCheck,    doneField,    doneBrowse),
            hookRow(seedingCheck, seedingField, seedingBrowse),
        ])
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        let outer = NSView()
        outer.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 20),
            mainStack.topAnchor.constraint(equalTo: outer.topAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: outer.trailingAnchor, constant: -20),
        ])
        view = outer
    }

    func load(_ s: Session) {
        addedCheck.state   = s.scriptTorrentAddedEnabled   ? .on : .off
        addedField.stringValue = s.scriptTorrentAddedFilename
        doneCheck.state    = s.scriptTorrentDoneEnabled    ? .on : .off
        doneField.stringValue  = s.scriptTorrentDoneFilename
        seedingCheck.state = s.scriptTorrentDoneSeedingEnabled ? .on : .off
        seedingField.stringValue = s.scriptTorrentDoneSeedingFilename
    }

    @objc private func apply() {
        var p = SessionPatch()
        p.scriptTorrentAddedEnabled          = addedCheck.state == .on
        p.scriptTorrentAddedFilename         = addedField.stringValue
        p.scriptTorrentDoneEnabled           = doneCheck.state == .on
        p.scriptTorrentDoneFilename          = doneField.stringValue
        p.scriptTorrentDoneSeedingEnabled    = seedingCheck.state == .on
        p.scriptTorrentDoneSeedingFilename   = seedingField.stringValue
        sendPatch(p)
    }

    @objc private func browseAdded()   { browseFile(field: addedField) }
    @objc private func browseDone()    { browseFile(field: doneField) }
    @objc private func browseSeeding() { browseFile(field: seedingField) }

    private func browseFile(field: NSTextField) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = S.Settings.Scripting.chooseScript
        guard let window = view.window else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            field.stringValue = url.path
            self?.apply()
        }
    }
}

// MARK: - Shared helpers

private func buildFormView(_ rows: [(String, NSView)]) -> NSView {
    let grid = NSGridView()
    grid.rowSpacing = 6; grid.columnSpacing = 8
    for (label, control) in rows {
        let lbl = NSTextField(labelWithString: label)
        lbl.alignment = .right
        lbl.font = .systemFont(ofSize: NSFont.systemFontSize)
        if let tf = control as? NSTextField, !(control is NSButton) {
            tf.font = .systemFont(ofSize: NSFont.systemFontSize)
            if tf.isEditable == false { tf.isEditable = true }
        }
        grid.addRow(with: [lbl, control])
    }
    if grid.numberOfColumns > 0 {
        grid.column(at: 0).width = 140
        grid.column(at: 0).xPlacement = .trailing
    }
    grid.translatesAutoresizingMaskIntoConstraints = false
     return grid
}

extension NSViewController {
    func sendPatch(_ patch: SessionPatch) {
        Task { [weak self] in
            guard let self = self else { return }
            let appService = (self as? GeneralSettingsTab)?.appService 
                          ?? (self as? ConnectionSettingsTab)?.appService 
                          ?? (self as? SpeedSettingsTab)?.appService 
                          ?? (self as? QueueSettingsTab)?.appService 
                          ?? (self as? NetworkSettingsTab)?.appService 
                          ?? (self as? ScriptingSettingsTab)?.appService
            try? await appService?.rpcSession?.setSession(patch)
            await appService?.refresh()
        }
    }
}
