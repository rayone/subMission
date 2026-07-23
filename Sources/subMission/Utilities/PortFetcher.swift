import Foundation

// MARK: - PortFetcher

/// Fetches a peer port number from a plain-text URL.
/// Accepts self-signed TLS certificates (needed for local router addresses like 10.0.0.1).
final class PortFetcher: Sendable {

    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 10
        let delegate = TrustAllDelegate()
        session = URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)
    }

    /// Returns the port number at `urlString` (plain-text integer), or nil on failure.
    func fetchPort(from urlString: String) async -> Int? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        do {
            let (data, _) = try await session.data(from: url)
            let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let port = Int(text), (1...65535).contains(port) else {
                return nil
            }
            return port
        } catch {
            return nil
        }
    }
}

// MARK: - TrustAllDelegate

/// URLSessionDelegate that accepts self-signed certificates.
/// Scoped to PortFetcher — not used for Transmission RPC traffic.
private final class TrustAllDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
