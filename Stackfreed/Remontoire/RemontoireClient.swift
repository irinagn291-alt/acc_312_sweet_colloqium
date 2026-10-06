import Foundation

/// Role: Remontoire. Typed hop failures. This product has no remote catalog.
enum RemontoireHopError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Remontoire. Injected carrier so tests never leave the process.
protocol RemontoireCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct RemontoireSessionCarrier: RemontoireCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": RemontoireClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Remontoire. Owns the session. Contact URL is opened by Settings, not fetched here.
actor RemontoireClient {
    static let userAgent = "Stackfreed/1.0 (iOS; +https://stackfreed-week.pro)"
    static let contactURL = URL(string: "https://stackfreed-week.pro/contact-us")!

    private let carrier: any RemontoireCarrying

    init(carrier: any RemontoireCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = RemontoireSessionCarrier()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw RemontoireHopError.cancelled
        } catch {
            throw RemontoireHopError.decoding
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as RemontoireHopError {
            throw error
        } catch is CancellationError {
            throw RemontoireHopError.cancelled
        } catch {
            if Self.cancelled(error) {
                throw RemontoireHopError.cancelled
            }
            guard Self.transient(error) else { throw RemontoireHopError.transport }
            do {
                return try await send(request)
            } catch let error as RemontoireHopError {
                throw error
            } catch is CancellationError {
                throw RemontoireHopError.cancelled
            } catch {
                if Self.cancelled(error) { throw RemontoireHopError.cancelled }
                throw RemontoireHopError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RemontoireHopError.invalidResponse
        }
        if http.statusCode == 404 {
            throw RemontoireHopError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw RemontoireHopError.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
