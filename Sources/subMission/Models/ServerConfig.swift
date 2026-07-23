import Foundation

// MARK: - ServerConfig

struct ServerConfig: Codable {
    var host: String     = "10.0.0.4"
    var port: Int        = 49091
    var path: String     = "/transmission/rpc"
    var useHTTPS: Bool   = false
    var username: String = "qnap"
    var password: String = "qnap"
    var pollInterval: Double = 2.0
    /// URL that returns the current peer port as plain text. Empty = disabled.
    var portPollURL: String  = ""

    private static var configURL: URL {
        AppPaths.applicationSupport.appendingPathComponent("config.json")
    }

    static func load() -> ServerConfig {
        guard let data = try? Data(contentsOf: configURL),
              let cfg  = try? JSONDecoder().decode(ServerConfig.self, from: data)
        else { return ServerConfig() }
        return cfg
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.configURL, options: .atomic)
    }
}
