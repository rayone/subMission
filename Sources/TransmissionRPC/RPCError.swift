import Foundation

public enum RPCError: Error, Sendable {
    case connectionFailed(URLError)
    case authenticationFailed
    case serverError(String)
    case decodingFailed(DecodingError)
    case timeout
}

extension RPCError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let urlError):
            return "Connection failed: \(urlError.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed (incorrect username or password)"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .decodingFailed(let err):
            return "Response decoding failed: \(err.localizedDescription)"
        case .timeout:
            return "Request timed out"
        }
    }
}
