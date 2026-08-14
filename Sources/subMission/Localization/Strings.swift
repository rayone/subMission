import Foundation

// MARK: - Localization helper

/// Resolves the SPM resource bundle in both development (.build/) and .app contexts.
private let localizationBundle: Bundle = {
    let bundleName = "subMission_subMission.bundle"

    // .app bundle: Contents/Resources/
    if let resourceURL = Bundle.main.resourceURL,
       let b = Bundle(url: resourceURL.appendingPathComponent(bundleName)) {
        return b
    }

    // SPM development: Bundle.module (generated accessor, searches .build/ and bundle root)
    return .module
}()

private func L(_ key: String, _ comment: String) -> String {
    NSLocalizedString(key, bundle: localizationBundle, comment: comment)
}

// MARK: - S — type-safe string constants
// All user-visible strings live here.
// To add a new translation: add a new <lang>.lproj/Localizable.strings file
// with the same keys and translated values.

enum S {

    // MARK: App menu
    enum App {
        static let about        = L("app.about",        "About menu item")
        static let preferences  = L("app.preferences",  "Preferences menu item")
        static let quit         = L("app.quit",          "Quit menu item")
    }

    // MARK: Edit menu
    enum Edit {
        static let menu       = L("edit.menu",        "Edit menu title")
        static let undo       = L("edit.undo",        "Undo menu item")
        static let redo       = L("edit.redo",        "Redo menu item")
        static let cut        = L("edit.cut",         "Cut menu item")
        static let copy       = L("edit.copy",        "Copy menu item")
        static let paste      = L("edit.paste",       "Paste menu item")
        static let selectAll  = L("edit.selectAll",   "Select All menu item")
        static let find       = L("edit.find",        "Find menu item")
    }

    // MARK: Torrent menu
    enum TorrentMenu {
        static let menu     = L("torrentmenu.menu",     "Torrent menu title")
        static let addFile  = L("torrentmenu.addFile",  "Add File menu item")
        static let addURL   = L("torrentmenu.addURL",   "Add URL menu item")
        static let start    = L("torrentmenu.start",    "Start menu item")
        static let stop     = L("torrentmenu.stop",     "Stop menu item")
    }

    // MARK: Window menu
    enum WindowMenu {
        static let menu     = L("windowmenu.menu",     "Window menu title")
        static let minimize = L("windowmenu.minimize", "Minimize menu item")
        static let zoom     = L("windowmenu.zoom",     "Zoom menu item")
    }

    // MARK: Toolbar
    enum Toolbar {
        static let add        = L("toolbar.add",        "Add toolbar item label")
        static let addTip     = L("toolbar.addTip",     "Add toolbar item tooltip")
        static let start      = L("toolbar.start",      "Start toolbar item label")
        static let startTip   = L("toolbar.startTip",   "Start toolbar item tooltip")
        static let stop       = L("toolbar.stop",       "Stop toolbar item label")
        static let stopTip    = L("toolbar.stopTip",    "Stop toolbar item tooltip")
        static let remove     = L("toolbar.remove",     "Remove toolbar item label")
        static let removeTip  = L("toolbar.removeTip",  "Remove toolbar item tooltip")
        static let controls   = L("toolbar.controls",   "Controls group label")
        static let altSpeed   = L("toolbar.altSpeed",   "Alt speed toolbar item label")
        static let altSpeedOn = L("toolbar.altSpeedOn", "Alt speed on label")
        static let altSpeedTip = L("toolbar.altSpeedTip", "Alt speed toolbar item tooltip")
        static let speed      = L("toolbar.speed",      "Speed toolbar item label")
        static let panels     = L("toolbar.panels",     "Panels toolbar item label")
        static let detailsTip = L("toolbar.detailsTip", "Toggle details tooltip")
        static let settings   = L("toolbar.settings",   "Settings toolbar item label")
        static let settingsTip = L("toolbar.settingsTip","Settings toolbar item tooltip")
    }

    // MARK: Torrent list context menu
    enum ContextMenu {
        static let resume          = L("ctx.resume",          "Resume context menu item")
        static let resumeNow       = L("ctx.resumeNow",       "Resume Now context menu item")
        static let pause           = L("ctx.pause",           "Pause context menu item")
        static let moveTop         = L("ctx.moveTop",         "Move to Top context menu item")
        static let moveUp          = L("ctx.moveUp",          "Move Up context menu item")
        static let moveDown        = L("ctx.moveDown",        "Move Down context menu item")
        static let moveBottom      = L("ctx.moveBottom",      "Move to Bottom context menu item")
        static let remove          = L("ctx.remove",          "Remove context menu item")
        static let removeWithData  = L("ctx.removeWithData",  "Remove and Delete Data context menu item")
        static let verify          = L("ctx.verify",          "Verify Local Data context menu item")
        static let setLocation     = L("ctx.setLocation",     "Set Location context menu item")
        static let rename          = L("ctx.rename",          "Rename context menu item")
        static let reannounce      = L("ctx.reannounce",      "Reannounce context menu item")
        static let selectAll       = L("ctx.selectAll",       "Select All context menu item")
        static let deselectAll     = L("ctx.deselectAll",     "Deselect All context menu item")
        static let groupBy         = L("ctx.groupBy",         "Group By context menu item")
        static let groupNone       = L("ctx.groupNone",       "None group by option")
        static let priority        = L("ctx.priority",        "Priority submenu title")
        static let priorityHigh    = L("ctx.priorityHigh",    "High priority context menu item")
        static let priorityNormal  = L("ctx.priorityNormal",  "Normal priority context menu item")
        static let priorityLow     = L("ctx.priorityLow",     "Low priority context menu item")
    }

    // MARK: Torrent list columns
    enum Column {
        static let name        = L("col.name",        "Name column header")
        static let status      = L("col.status",      "Status column header")
        static let progress    = L("col.progress",    "Progress column header")
        static let size        = L("col.size",        "Size column header")
        static let downloaded  = L("col.downloaded",  "Downloaded column header")
        static let uploaded    = L("col.uploaded",    "Uploaded column header")
        static let ratio       = L("col.ratio",       "Ratio column header")
        static let dlSpeed     = L("col.dlSpeed",     "DL Speed column header")
        static let ulSpeed     = L("col.ulSpeed",     "UL Speed column header")
        static let eta         = L("col.eta",         "ETA column header")
        static let seeds       = L("col.seeds",       "Seeds column header")
        static let peers       = L("col.peers",       "Peers column header")
        static let queue       = L("col.queue",       "Queue column header")
        static let location    = L("col.location",    "Location column header")
    }

    // MARK: Add torrent panel
    enum AddTorrent {
        static let openPanelMessage  = L("add.openPanelMessage",  "Open panel message when choosing .torrent file")
        static let labelName         = L("add.labelName",         "Name label in Add Torrent sheet")
        static let labelSaveTo       = L("add.labelSaveTo",       "Save To label in Add Torrent sheet")
        static let labelPriority     = L("add.labelPriority",     "Priority label in Add Torrent sheet")
        static let startWhenAdded    = L("add.startWhenAdded",    "Start when added checkbox")
        static let colName           = L("add.colName",           "Name column in Add Torrent sheet file list")
        static let colSize           = L("add.colSize",           "Size column in Add Torrent sheet file list")
        static let priorityHigh      = L("add.priorityHigh",      "High priority option")
        static let priorityNormal    = L("add.priorityNormal",    "Normal priority option")
        static let priorityLow       = L("add.priorityLow",       "Low priority option")
        static let addButton         = L("add.addButton",         "Add button title")
        static let cancelButton      = L("add.cancelButton",      "Cancel button title")
    }

    // MARK: Add URL sheet
    enum AddURL {
        static let labelURL      = L("addurl.labelURL",      "Magnet/URL label")
        static let labelSaveTo   = L("addurl.labelSaveTo",   "Save To label in Add URL sheet")
        static let startWhenAdded = L("addurl.startWhenAdded","Start when added checkbox in Add URL sheet")
        static let addButton     = L("addurl.addButton",     "Add button in Add URL sheet")
        static let cancelButton  = L("addurl.cancelButton",  "Cancel button in Add URL sheet")
        static let magnetFallback = L("addurl.magnetFallback","Fallback display name for magnet links")
    }

    // MARK: Set Location sheet
    enum SetLocation {
        static let labelLocation = L("setloc.labelLocation", "Location label in Set Location sheet")
        static let moveData      = L("setloc.moveData",      "Move existing data checkbox")
        static let okButton      = L("setloc.okButton",      "Set Location button title")
        static let cancelButton  = L("setloc.cancelButton",  "Cancel button in Set Location sheet")
    }

    // MARK: Rename sheet
    enum Rename {
        static let labelNewName  = L("rename.labelNewName",  "New name label in Rename sheet")
        static let okButton      = L("rename.okButton",      "Rename button title")
        static let cancelButton  = L("rename.cancelButton",  "Cancel button in Rename sheet")
    }

    // MARK: Remove alert
    enum RemoveAlert {
        static func message(count: Int, deleteData: Bool) -> String {
            deleteData
                ? String(format: L("remove.messageDelete", "Delete N torrents and data alert text"), count)
                : String(format: L("remove.messageRemove", "Remove N torrents alert text"), count)
        }
        static func detail(deleteData: Bool) -> String {
            deleteData
                ? L("remove.detailDelete", "Detail text when deleting data")
                : L("remove.detailRemove", "Detail text when not deleting data")
        }
        static let deleteButton  = L("remove.deleteButton",  "Delete button in remove alert")
        static let removeButton  = L("remove.removeButton",  "Remove button in remove alert")
        static let cancelButton  = L("remove.cancelButton",  "Cancel button in remove alert")
    }

    // MARK: Error alert
    enum ErrorAlert {
        static let title     = L("error.title",     "Generic operation failed alert title")
        static let okButton  = L("error.okButton",  "OK button in error alert")
    }

    // MARK: Filters sidebar
    enum Filter {
        static let statusHeader = L("filter.statusHeader", "STATUS section header in filters sidebar")
        static let labelsHeader = L("filter.labelsHeader", "LABELS section header in filters sidebar")
        static let all          = L("filter.all",          "All filter")
        static let downloading  = L("filter.downloading",  "Downloading filter")
        static let seeding      = L("filter.seeding",      "Seeding filter")
        static let completed    = L("filter.completed",    "Completed filter")
        static let active       = L("filter.active",       "Active filter")
        static let inactive     = L("filter.inactive",     "Inactive filter")
        static let error        = L("filter.error",        "Error filter")
        static let noLabel      = L("filter.noLabel",      "No Label filter")
    }

    // MARK: Torrent details tabs
    enum Details {
        static let tabInfo      = L("details.tabInfo",      "Info tab label")
        static let tabFiles     = L("details.tabFiles",     "Files tab label")
        static let tabTrackers  = L("details.tabTrackers",  "Trackers tab label")
        static let tabPeers     = L("details.tabPeers",     "Peers tab label")
        static let tabLimits    = L("details.tabLimits",    "Limits tab label")
        static let noSelection  = L("details.noSelection",  "Placeholder when no torrent is selected")
        static func multiSelection(count: Int) -> String {
            String(format: L("details.multiSelection", "Placeholder when multiple torrents are selected"), count)
        }
    }

    // MARK: Info tab
    enum Info {
        static let name         = L("info.name",         "Name row label")
        static let hash         = L("info.hash",         "Hash row label")
        static let comment      = L("info.comment",      "Comment row label")
        static let creator      = L("info.creator",      "Creator row label")
        static let created      = L("info.created",      "Created row label")
        static let isPrivate    = L("info.isPrivate",    "Private row label")
        static let location     = L("info.location",     "Location row label")
        static let statusRow    = L("info.statusRow",    "Status row label")
        static let downloaded   = L("info.downloaded",   "Downloaded row label")
        static let uploaded     = L("info.uploaded",     "Uploaded row label")
        static let ratio        = L("info.ratio",        "Ratio row label")
        static let dlSpeed      = L("info.dlSpeed",      "DL Speed row label")
        static let ulSpeed      = L("info.ulSpeed",      "UL Speed row label")
        static let timeDl       = L("info.timeDl",       "Time DL row label")
        static let timeSeeding  = L("info.timeSeeding",  "Time Seeding row label")
        static let totalSize    = L("info.totalSize",    "Total Size row label")
        static let have         = L("info.have",         "Have row label")
        static let remaining    = L("info.remaining",    "Remaining row label")
        static let corrupt      = L("info.corrupt",      "Corrupt row label")
        static let added        = L("info.added",        "Added row label")
        static let completed    = L("info.completed",    "Completed row label")
        static let lastActive   = L("info.lastActive",   "Last Active row label")
        static let yes          = L("info.yes",          "Yes value for boolean fields")
        static let no           = L("info.no",           "No value for boolean fields")
        static let renameTip    = L("info.renameTip",    "Tooltip on rename button")
        static let setLocTip    = L("info.setLocTip",    "Tooltip on set location button")
    }

    // MARK: Files tab
    enum Files {
        static let colName    = L("files.colName",   "Name column in files tab")
        static let colSize    = L("files.colSize",   "Size column in files tab")
        static let colProgress = L("files.colProgress", "Progress column in files tab")
        static let colPriority = L("files.colPriority", "Priority column in files tab")
        static let colWanted  = L("files.colWanted", "Wanted column in files tab")
        static let priorityHigh   = L("files.priorityHigh",   "High priority option in files tab")
        static let priorityNormal = L("files.priorityNormal", "Normal priority option in files tab")
        static let priorityLow    = L("files.priorityLow",    "Low priority option in files tab")
    }

    // MARK: Trackers tab
    enum Trackers {
        static let colTracker  = L("trackers.colTracker",  "Tracker column header")
        static let colStatus   = L("trackers.colStatus",   "Status column header")
        static let colSeeds    = L("trackers.colSeeds",    "Seeds column header")
        static let colPeers    = L("trackers.colPeers",    "Peers column header")
        static let colDL       = L("trackers.colDL",       "DL column header")
        static let updateButton = L("trackers.updateButton","Update Trackers button title")
    }

    // MARK: Peers tab
    enum Peers {
        static let colAddress  = L("peers.colAddress",  "Address column header")
        static let colClient   = L("peers.colClient",   "Client column header")
        static let colProgress = L("peers.colProgress", "Progress column header")
        static let colDLRate   = L("peers.colDLRate",   "DL Rate column header")
        static let colULRate   = L("peers.colULRate",   "UL Rate column header")
        static let colFlags    = L("peers.colFlags",    "Flags column header")
        static func fromSummary(tracker: Int, dht: Int, pex: Int, lpd: Int, incoming: Int, cache: Int) -> String {
            String(format: L("peers.fromSummary", "Peers from summary line"), tracker, dht, pex, lpd, incoming, cache)
        }
    }

    // MARK: Limits tab
    enum Limits {
        static let sectionSpeed   = L("limits.sectionSpeed",   "SPEED LIMITS section header")
        static let sectionSeeding = L("limits.sectionSeeding", "SEEDING LIMITS section header")
        static let sectionOther   = L("limits.sectionOther",   "OTHER section header")
        static let download       = L("limits.download",       "Download row label")
        static let upload         = L("limits.upload",         "Upload row label")
        static let honorSession   = L("limits.honorSession",   "Honor session row label")
        static let priority       = L("limits.priority",       "Priority row label")
        static let ratioMode      = L("limits.ratioMode",      "Ratio mode row label")
        static let ratioLimit     = L("limits.ratioLimit",     "Ratio limit row label")
        static let idleMode       = L("limits.idleMode",       "Idle mode row label")
        static let idleLimit      = L("limits.idleLimit",      "Idle limit row label")
        static let peerLimit      = L("limits.peerLimit",      "Peer limit row label")
        static let sequentialDL   = L("limits.sequentialDL",   "Sequential DL row label")
        static let kbps           = L("limits.kbps",           "kB/s unit label")
        static let ratio          = L("limits.ratio",          "ratio unit placeholder")
        static let minutes        = L("limits.minutes",        "min unit placeholder")
        static let bwPriorityLow    = L("limits.bwPriorityLow",    "Low bandwidth priority segment label")
        static let bwPriorityNormal = L("limits.bwPriorityNormal", "Normal bandwidth priority segment label")
        static let bwPriorityHigh   = L("limits.bwPriorityHigh",   "High bandwidth priority segment label")
        static let seedModeGlobal    = L("limits.seedModeGlobal",    "Use Global seed mode option")
        static let seedModeStop      = L("limits.seedModeStop",      "Stop at ratio seed mode option")
        static let seedModeForever   = L("limits.seedModeForever",   "Seed indefinitely option")
        static let downloadLimitTip  = L("limits.downloadLimitTip",  "Download limit tooltip")
        static let uploadLimitTip    = L("limits.uploadLimitTip",    "Upload limit tooltip")
        static let honorSessionTip   = L("limits.honorSessionTip",   "Honor session tooltip")
        static let priorityTip       = L("limits.priorityTip",       "Bandwidth priority tooltip")
        static let ratioModeTip      = L("limits.ratioModeTip",      "Ratio mode tooltip")
        static let ratioLimitTip     = L("limits.ratioLimitTip",     "Ratio limit tooltip")
        static let idleModeTip       = L("limits.idleModeTip",       "Idle mode tooltip")
        static let idleLimitTip      = L("limits.idleLimitTip",      "Idle limit tooltip")
        static let peerLimitTip      = L("limits.peerLimitTip",      "Peer limit tooltip")
        static let sequentialDLTip   = L("limits.sequentialDLTip",   "Sequential DL tooltip")
    }

    // MARK: Status footer
    enum Footer {
        static let notConfigured   = L("footer.notConfigured",   "Not configured host label in footer")
        static let freeSpaceUnknown = L("footer.freeSpaceUnknown","Unknown free space label")
        static func freeSpace(formatted: String) -> String {
            String(format: L("footer.freeSpace", "Free space label with value"), formatted)
        }
        static func torrentCount(total: Int, active: Int) -> String {
            String(format: L("footer.torrentCount", "Torrent count label with active count"), total, active)
        }
        static func torrentCountNoActive(total: Int) -> String {
            String(format: L("footer.torrentCountNoActive", "Torrent count label without active count"), total)
        }
        static let transmissionVersion = L("footer.transmissionVersion", "Transmission version tooltip line")
        static let rpcVersion          = L("footer.rpcVersion",          "RPC version tooltip line")
        static let peerPort            = L("footer.peerPort",            "Peer port tooltip line")
        static let portSync            = L("footer.portSync",            "Port sync tooltip line")
        static let errorLine           = L("footer.errorLine",           "Error tooltip line")
    }

    // MARK: Status strings (Formatters)
    enum Status {
        static func error(message: String) -> String {
            String(format: L("status.error", "Error status with message"), message)
        }
        static let stopped          = L("status.stopped",          "Stopped status")
        static let queuedVerify     = L("status.queuedVerify",     "Queued for verification status")
        static func verifying(percent: Int) -> String {
            String(format: L("status.verifying", "Verifying status with percent"), percent)
        }
        static let queuedDownload   = L("status.queuedDownload",   "Queued for download status")
        static func metadata(percent: Int) -> String {
            String(format: L("status.metadata", "Retrieving metadata status with percent"), percent)
        }
        static let downloading      = L("status.downloading",      "Downloading status")
        static let queuedSeed       = L("status.queuedSeed",       "Queued for seeding status")
        static let seeding          = L("status.seeding",          "Seeding status")
        static let etaDone          = L("status.etaDone",          "ETA done value")
    }

    // MARK: Port sync messages (AppService)
    enum PortSync {
        static let fetchFailed     = L("portsync.fetchFailed",     "Port fetch failure message")
        static func notConnected(port: Int) -> String {
            String(format: L("portsync.notConnected", "Port not connected message"), port)
        }
        static func alreadyInSync(port: Int) -> String {
            String(format: L("portsync.alreadyInSync", "Port already in sync message"), port)
        }
        static func updated(port: Int) -> String {
            String(format: L("portsync.updated", "Port updated message"), port)
        }
        static func updateFailed(reason: String) -> String {
            String(format: L("portsync.updateFailed", "Port update failed message"), reason)
        }
    }

    // MARK: Settings window
    enum Settings {

        static let title = L("settings.title", "Settings window title")

        // MARK: Tab names
        enum Tab {
            static let connection = L("settings.tab.connection", "Connection tab name")
            static let general    = L("settings.tab.general",    "General tab name")
            static let speed      = L("settings.tab.speed",      "Speed tab name")
            static let queue      = L("settings.tab.queue",      "Queue tab name")
            static let network    = L("settings.tab.network",    "Network tab name")
            static let scripting  = L("settings.tab.scripting",  "Scripting tab name")
        }

        // MARK: Section headers
        enum Section {
            static let connection = L("settings.section.connection", "CONNECTION section header")
            static let download   = L("settings.section.download",   "DOWNLOAD section header")
            static let speed      = L("settings.section.speed",      "SPEED LIMITS section header")
            static let queue      = L("settings.section.queue",      "QUEUE section header")
            static let network    = L("settings.section.network",    "NETWORK section header")
        }

        // MARK: Connection tab
        enum Connection {
            static let host           = L("settings.connection.host",           "Host field label")
            static let hostTip        = L("settings.connection.hostTip",        "Host field tooltip")
            static let rpcPort        = L("settings.connection.rpcPort",        "RPC Port field label")
            static let rpcPortTip     = L("settings.connection.rpcPortTip",     "RPC Port field tooltip")
            static let path           = L("settings.connection.path",           "Path field label")
            static let pathTip        = L("settings.connection.pathTip",        "Path field tooltip")
            static let username       = L("settings.connection.username",       "Username field label")
            static let usernameTip    = L("settings.connection.usernameTip",    "Username field tooltip")
            static let password       = L("settings.connection.password",       "Password field label")
            static let passwordTip    = L("settings.connection.passwordTip",    "Password field tooltip")
            static let useHTTPS       = L("settings.connection.useHTTPS",       "Use HTTPS checkbox label")
            static let useHTTPSTip    = L("settings.connection.useHTTPSTip",    "Use HTTPS checkbox tooltip")
            static let poll           = L("settings.connection.poll",           "Poll interval field label")
            static let pollTip        = L("settings.connection.pollTip",        "Poll interval field tooltip")
            static let testButton     = L("settings.connection.testButton",     "Test Connection button title")
            static let connecting     = L("settings.connection.connecting",     "Connecting… status while testing")
            static func connected(version: String) -> String {
                String(format: L("settings.connection.connected", "Connected status with version"), version)
            }
            static func failed(reason: String) -> String {
                String(format: L("settings.connection.failed", "Connection failed status with reason"), reason)
            }
            static let hostLabel      = L("settings.connection.hostLabel",      "Host: label in form")
            static let portLabel      = L("settings.connection.portLabel",      "Port: label in form")
            static let pathLabel      = L("settings.connection.pathLabel",      "RPC Path: label in form")
            static let usernameLabel  = L("settings.connection.usernameLabel",  "Username: label in form")
            static let passwordLabel  = L("settings.connection.passwordLabel",  "Password: label in form")
            static let pollLabel      = L("settings.connection.pollLabel",      "Poll interval (s): label in form")
        }

        // MARK: General / Download tab
        enum Download {
            static let directory      = L("settings.download.directory",      "Directory field label")
            static let directoryTip   = L("settings.download.directoryTip",   "Directory field tooltip")
            static let incomplete     = L("settings.download.incomplete",      "Incomplete dir field label")
            static let incompleteTip  = L("settings.download.incompleteTip",  "Incomplete dir field tooltip")
            static let start          = L("settings.download.start",          "Start on add checkbox label")
            static let startTip       = L("settings.download.startTip",       "Start on add checkbox tooltip")
            static let trash          = L("settings.download.trash",          "Trash .torrent checkbox label")
            static let trashTip       = L("settings.download.trashTip",       "Trash .torrent checkbox tooltip")
            static let appendPart     = L("settings.download.appendPart",     "Append .part checkbox label")
            static let appendPartTip  = L("settings.download.appendPartTip",  "Append .part checkbox tooltip")
            static let incompCheck    = L("settings.download.incompCheck",    "Use incomplete dir checkbox label")
            static let startCheck     = L("settings.download.startCheck",     "Start added torrents checkbox label")
            static let trashCheck     = L("settings.download.trashCheck",     "Trash .torrent file checkbox label")
            static let renameCheck    = L("settings.download.renameCheck",    "Append .part checkbox full label")
            static let dlDirLabel     = L("settings.download.dlDirLabel",     "Download dir: form label")
            static let incompDirLabel = L("settings.download.incompDirLabel", "Incomplete dir: form label")
            static let trackersLabel  = L("settings.download.trackersLabel",  "Default trackers: form label")
        }

        // MARK: Speed tab
        enum Speed {
            static let download       = L("settings.speed.download",       "Download (kB/s) label")
            static let downloadTip    = L("settings.speed.downloadTip",    "Download speed tooltip")
            static let upload         = L("settings.speed.upload",         "Upload (kB/s) label")
            static let uploadTip      = L("settings.speed.uploadTip",      "Upload speed tooltip")
            static let altDownload    = L("settings.speed.altDownload",    "Alt. download (kB/s) label")
            static let altDownloadTip = L("settings.speed.altDownloadTip", "Alt download speed tooltip")
            static let altUpload      = L("settings.speed.altUpload",      "Alt. upload (kB/s) label")
            static let altUploadTip   = L("settings.speed.altUploadTip",   "Alt upload speed tooltip")
            static let dlLimitCheck   = L("settings.speed.dlLimitCheck",   "Download limit checkbox label")
            static let ulLimitCheck   = L("settings.speed.ulLimitCheck",   "Upload limit checkbox label")
            static let altSchedCheck  = L("settings.speed.altSchedCheck",  "Schedule alt speed checkbox label")
            static let dlKbps         = L("settings.speed.dlKbps",         "DL kB/s: form label")
            static let ulKbps         = L("settings.speed.ulKbps",         "UL kB/s: form label")
            static let altDlKbps      = L("settings.speed.altDlKbps",      "Alt DL kB/s: form label")
            static let altUlKbps      = L("settings.speed.altUlKbps",      "Alt UL kB/s: form label")
            static let altBegin       = L("settings.speed.altBegin",       "Alt begin (mins): form label")
            static let altEnd         = L("settings.speed.altEnd",         "Alt end (mins): form label")
        }

        // MARK: Queue tab
        enum Queue {
            static let maxDownloads    = L("settings.queue.maxDownloads",    "Max downloads label")
            static let maxDownloadsTip = L("settings.queue.maxDownloadsTip", "Max downloads tooltip")
            static let maxSeeds        = L("settings.queue.maxSeeds",        "Max seeds label")
            static let maxSeedsTip     = L("settings.queue.maxSeedsTip",     "Max seeds tooltip")
            static let ratioLimit      = L("settings.queue.ratioLimit",      "Ratio limit label")
            static let ratioLimitTip   = L("settings.queue.ratioLimitTip",   "Ratio limit tooltip")
            static let idleLimit       = L("settings.queue.idleLimit",       "Idle (min) label")
            static let idleLimitTip    = L("settings.queue.idleLimitTip",    "Idle limit tooltip")
            static let dlQueueCheck    = L("settings.queue.dlQueueCheck",    "Limit active downloads checkbox")
            static let seedQueueCheck  = L("settings.queue.seedQueueCheck",  "Limit active seeds checkbox")
            static let stalledCheck    = L("settings.queue.stalledCheck",    "Consider torrents stalled checkbox")
            static let seedRatioCheck  = L("settings.queue.seedRatioCheck",  "Seed ratio limit checkbox")
            static let idleLimitCheck  = L("settings.queue.idleLimitCheck",  "Idle seed limit checkbox")
            static let dlQueueLabel    = L("settings.queue.dlQueueLabel",    "DL queue size: form label")
            static let seedQueueLabel  = L("settings.queue.seedQueueLabel",  "Seed queue size: form label")
            static let stalledLabel    = L("settings.queue.stalledLabel",    "Stalled (min): form label")
            static let ratioLimitLabel = L("settings.queue.ratioLimitLabel", "Ratio limit: form label")
            static let idleLimitLabel  = L("settings.queue.idleLimitLabel",  "Idle limit (min): form label")
        }

        // MARK: Network tab
        enum Network {
            static let peerPort         = L("settings.network.peerPort",         "Peer port label")
            static let peerPortTip      = L("settings.network.peerPortTip",      "Peer port tooltip")
            static let autoPortURL      = L("settings.network.autoPortURL",      "Auto-port URL label")
            static let autoPortURLTip   = L("settings.network.autoPortURLTip",   "Auto-port URL tooltip")
            static let upnp             = L("settings.network.upnp",             "UPnP / NAT-PMP label")
            static let upnpTip          = L("settings.network.upnpTip",          "UPnP tooltip")
            static let pex              = L("settings.network.pex",              "PEX label")
            static let pexTip           = L("settings.network.pexTip",           "PEX tooltip")
            static let dht              = L("settings.network.dht",              "DHT label")
            static let dhtTip           = L("settings.network.dhtTip",           "DHT tooltip")
            static let lpd              = L("settings.network.lpd",              "LPD label")
            static let lpdTip           = L("settings.network.lpdTip",           "LPD tooltip")
            static let randomPortCheck  = L("settings.network.randomPortCheck",  "Randomize port on start checkbox")
            static let upnpCheck        = L("settings.network.upnpCheck",        "Use UPnP checkbox")
            static let pexCheck         = L("settings.network.pexCheck",         "PEX checkbox")
            static let dhtCheck         = L("settings.network.dhtCheck",         "DHT checkbox")
            static let lpdCheck         = L("settings.network.lpdCheck",         "LPD checkbox")
            static let blocklistCheck   = L("settings.network.blocklistCheck",   "Blocklist enabled checkbox")
            static let testPortButton   = L("settings.network.testPortButton",   "Test Port button title")
            static let updateBLButton   = L("settings.network.updateBLButton",   "Update Blocklist button title")
            static let portLabel        = L("settings.network.portLabel",        "Port: form label")
            static let peerLimitGlobal  = L("settings.network.peerLimitGlobal",  "Global peer limit: form label")
            static let peerLimitPerTorrent = L("settings.network.peerLimitPerTorrent", "Per-torrent limit: form label")
            static let encryption       = L("settings.network.encryption",       "Encryption: form label")
            static let encRequired      = L("settings.network.encRequired",      "Required encryption option")
            static let encPreferred     = L("settings.network.encPreferred",     "Preferred encryption option")
            static let encAllowed       = L("settings.network.encAllowed",       "Allowed encryption option")
            static let blocklistURL     = L("settings.network.blocklistURL",     "Blocklist URL: form label")
            static func portOpen() -> String   { L("settings.network.portOpen",   "Port is open status") }
            static func portClosed() -> String { L("settings.network.portClosed", "Port is closed status") }
            static func portFailed(reason: String) -> String {
                String(format: L("settings.network.portFailed", "Port test failed status"), reason)
            }
        }

        // MARK: Scripting tab
        enum Scripting {
            static let addedCheck    = L("settings.scripting.addedCheck",    "Run script when torrent is added checkbox")
            static let doneCheck     = L("settings.scripting.doneCheck",     "Run script when download completes checkbox")
            static let seedingCheck  = L("settings.scripting.seedingCheck",  "Run script when seeding completes checkbox")
            static let browseButton  = L("settings.scripting.browseButton",  "Browse… button title")
            static let chooseScript  = L("settings.scripting.chooseScript",  "Open panel message when choosing script")
        }

        // MARK: Placeholders
        static let unlimited = L("settings.unlimited", "Unlimited placeholder")
        static let disabled  = L("settings.disabled",  "Disabled placeholder")
    }
}
