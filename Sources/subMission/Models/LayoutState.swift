import Foundation

// MARK: - LayoutState

struct LayoutState: Codable {
    var sortKey: String              = "name"
    var sortAscending: Bool          = true
    var groupByKey: String?          = nil
    var columnWidths: [String: Double]  = [:]
    var hiddenColumns: [String]         = ["downloaded", "uploaded", "location"]
    var columnOrder: [String]           = []
    var mainSplitPosition: Double?      = nil
    var windowWidth: Double             = 1100
    var windowHeight: Double            = 680
    /// Last download directory chosen by the user in any add/set-location sheet.
    var lastUsedDir: String?            = nil

    private static var layoutURL: URL {
        AppPaths.applicationSupport.appendingPathComponent("layout.json")
    }

    static func load() -> LayoutState {
        guard let data = try? Data(contentsOf: layoutURL),
              let state = try? JSONDecoder().decode(LayoutState.self, from: data)
        else { return LayoutState() }
        return state
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.layoutURL, options: .atomic)
    }

    /// Save just the lastUsedDir field without loading/writing full state (cheap).
    static func saveLastUsedDir(_ dir: String) {
        guard !dir.isEmpty else { return }
        var state = load()
        state.lastUsedDir = dir
        state.save()
    }
}
