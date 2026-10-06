import XCTest
@testable import Stackfreed

private struct ProbeDTO: Decodable {
    var note: String
}

private actor ScriptedCarrier: RemontoireCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class RemontoireClientTests: XCTestCase {
    private let url = URL(string: "https://stackfreed-week.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"note\":\"ok\"}".utf8), http(200))),
        ])
        let client = RemontoireClient(carrier: carrier)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), RemontoireClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(RemontoireClient.userAgent, "Stackfreed/1.0 (iOS; +https://stackfreed-week.pro)")
        XCTAssertEqual(RemontoireClient.contactURL.absoluteString, "https://stackfreed-week.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"note\":\"ok\"}".utf8), http(200))),
        ])
        let client = RemontoireClient(carrier: carrier)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.note, "ok")
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"note\":\"ok\"}".utf8), http(200))),
        ])
        let client = RemontoireClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? RemontoireHopError, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = RemontoireClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? RemontoireHopError, .decoding)
        }
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
