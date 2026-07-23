import Foundation

// MARK: - RPC Response Envelope

struct RPCResultOnly: Decodable {
    let result: String
}

struct RPCResponse<T: Decodable>: Decodable {
    let result: String
    let arguments: T?
}

struct EmptyArguments: Decodable {}

struct RPCRequestEnvelope<A: Encodable>: Encodable {
    let method: String
    let arguments: A
}

// MARK: - RPCSession Actor

public actor RPCSession {
    private let transport: any TransportProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public var host: String {
        get async {
            if let http = transport as? HTTPTransport {
                return http.host
            }
            return "unknown"
        }
    }
    
    public var port: Int {
        get async {
            if let http = transport as? HTTPTransport {
                return http.port
            }
            return 0
        }
    }

    public init(transport: any TransportProtocol) {
        self.transport = transport
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Generic Request

    public func request<A: Encodable, R: Decodable>(
        method: String,
        arguments: A,
        responseType: R.Type
    ) async throws -> R {
        let body = try buildRequestBody(method: method, arguments: arguments)
        let urlRequest = buildURLRequest(body: body)
        let data = try await transport.send(request: urlRequest)
        
        let resultOnly = try decode(RPCResultOnly.self, from: data)
        guard resultOnly.result == "success" else {
            throw RPCError.serverError(resultOnly.result)
        }
        
        let envelope = try decode(RPCResponse<R>.self, from: data)
        guard let args = envelope.arguments else {
            throw RPCError.serverError("Missing arguments in response")
        }
        return args
    }

    /// Fire-and-forget variant (response arguments ignored).
    /// torrent-rename-path quirk: some Transmission versions return "Invalid argument"
    /// even on success when the name contains special characters — but still include
    /// the renamed torrent in the response arguments. We treat such responses as success.
    public func requestVoid<A: Encodable>(
        method: String,
        arguments: A
    ) async throws {
        let body = try buildRequestBody(method: method, arguments: arguments)
        let urlRequest = buildURLRequest(body: body)
        let data = try await transport.send(request: urlRequest)

        // For rename, check if server returned an id in arguments (success indicator)
        // because some Transmission versions report "Invalid argument" spuriously.
        if method == "torrent-rename-path" {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let args = json["arguments"] as? [String: Any],
               args["id"] != nil {
                return  // rename succeeded despite result string
            }
        }

        let resultOnly = try decode(RPCResultOnly.self, from: data)
        guard resultOnly.result == "success" else {
            throw RPCError.serverError(resultOnly.result)
        }
    }

    // MARK: - Private Helpers

    private func buildRequestBody<A: Encodable>(method: String, arguments: A) throws -> Data {
        let envelope = RPCRequestEnvelope(method: method, arguments: arguments)
        do {
            return try encoder.encode(envelope)
        } catch {
            throw RPCError.serverError("Encoding failed: \(error)")
        }
    }

    private func buildURLRequest(body: Data) -> URLRequest {
        // Transport owns the URL; we just wrap the body.
        // The transport's send(request:) routes it to the correct endpoint.
        // We create a placeholder URL — transport replaces it.
        var req = URLRequest(url: URL(string: "http://placeholder")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        return req
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            throw RPCError.decodingFailed(error)
        }
    }
}
