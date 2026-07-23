import Foundation

// MARK: - Transport Protocol

public protocol TransportProtocol: Sendable {
    func send(request: URLRequest) async throws -> Data
}

// MARK: - HTTP Transport

public actor HTTPTransport: TransportProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let credentials: (username: String, password: String)?
    private var sessionID: String?
    private var activeSessionTask: Task<String, Error>?
    private let timeout: TimeInterval
    
    public let host: String
    public let port: Int

    public init(
        host: String,
        port: Int = 9091,
        path: String = "/transmission/rpc",
        useHTTPS: Bool = false,
        username: String? = nil,
        password: String? = nil,
        timeout: TimeInterval = 30
    ) {
        self.host = host
        self.port = port
        let scheme = useHTTPS ? "https" : "http"
        self.baseURL = URL(string: "\(scheme)://\(host):\(port)\(path)")!
        self.timeout = timeout

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)

        if let username, let password, !username.isEmpty {
            self.credentials = (username, password)
        } else {
            self.credentials = nil
        }
    }

    public func send(request: URLRequest) async throws -> Data {
        // Stamp the real base URL onto the request (caller uses placeholder)
        var req = request
        req.url = baseURL
        applyAuth(to: &req)
        
        // Wait for an active session ID refresh if there is one
        if let task = activeSessionTask {
            if let sid = try? await task.value {
                req.setValue(sid, forHTTPHeaderField: "X-Transmission-Session-Id")
            }
        } else if let sid = sessionID {
            req.setValue(sid, forHTTPHeaderField: "X-Transmission-Session-Id")
        }

        let (data, _) = try await fetchWithRetry(request: req)
        return data
    }

    // MARK: - Private

    private func applyAuth(to request: inout URLRequest) {
        guard let creds = credentials else { return }
        let raw = "\(creds.username):\(creds.password)"
        if let encoded = raw.data(using: .utf8)?.base64EncodedString() {
            request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        }
    }

    private func fetchWithRetry(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var req = request
        if let sid = sessionID {
            req.setValue(sid, forHTTPHeaderField: "X-Transmission-Session-Id")
        }

        let (data, raw) = try await performRequest(req)
        guard let httpResp = raw as? HTTPURLResponse else {
            throw RPCError.connectionFailed(URLError(.badServerResponse))
        }

        switch httpResp.statusCode {
        case 200:
            return (data, httpResp)
        case 401:
            throw RPCError.authenticationFailed
        case 409:
            // Handle session ID refresh
            let newSID: String
            
            if let task = activeSessionTask {
                // If a refresh is already in progress, wait for it
                newSID = try await task.value
            } else if let sidHeader = httpResp.value(forHTTPHeaderField: "X-Transmission-Session-Id") {
                // Start a new refresh task
                let task = Task<String, Error> {
                    self.sessionID = sidHeader
                    return sidHeader
                }
                activeSessionTask = task
                do {
                    newSID = try await task.value
                    activeSessionTask = nil
                } catch {
                    activeSessionTask = nil
                    throw error
                }
            } else {
                throw RPCError.serverError("409 with no session ID header")
            }

            var retry = request
            retry.setValue(newSID, forHTTPHeaderField: "X-Transmission-Session-Id")
            applyAuth(to: &retry)
            
            let (retryData, retryRaw) = try await performRequest(retry)
            guard let retryResp = retryRaw as? HTTPURLResponse else {
                throw RPCError.connectionFailed(URLError(.badServerResponse))
            }
            switch retryResp.statusCode {
            case 200:
                return (retryData, retryResp)
            case 401:
                throw RPCError.authenticationFailed
            default:
                throw RPCError.serverError("Unexpected status after 409 retry")
            }
        default:
            throw RPCError.serverError("HTTP \(httpResp.statusCode)")
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .timedOut {
                throw RPCError.timeout
            }
            throw RPCError.connectionFailed(error)
        }
    }
}
