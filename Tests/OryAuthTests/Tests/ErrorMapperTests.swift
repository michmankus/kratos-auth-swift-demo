//
//  ErrorMapperTests.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
import Testing
@testable import OryAuth
@testable import OryClient

@Suite("OryErrorMapper")
struct OryErrorMapperTests {

    @Test func passesThroughExistingOryError() {
        let original = OryError.unauthorized
        let mapped = OryErrorMapper.flatMap(original)

        guard case .unauthorized = mapped else {
            Issue.record("Expected .unauthorized, got \(mapped)")
            return
        }
    }

    @Test func mapsURLErrorToNetwork() {
        let urlError = URLError(.notConnectedToInternet)
        let mapped = OryErrorMapper.flatMap(urlError)

        guard case .network = mapped else {
            Issue.record("Expected .network, got \(mapped)")
            return
        }
    }

    @Test func mapsUnknownErrorToNetwork() {
        struct SomeError: Error {}
        let mapped = OryErrorMapper.flatMap(SomeError())

        guard case .network = mapped else {
            Issue.record("Expected .network, got \(mapped)")
            return
        }
    }

    @Test func maps401ToUnauthorized() {
        let errorResponse = OryClient.ErrorResponse.error(401, nil, nil, StubError())
        let mapped = OryErrorMapper.flatMap(errorResponse)

        guard case .unauthorized = mapped else {
            Issue.record("Expected .unauthorized, got \(mapped)")
            return
        }
    }

    @Test func maps400WithNoDataToUnknown() {
        let errorResponse = OryClient.ErrorResponse.error(400, nil, nil, StubError())
        let mapped = OryErrorMapper.flatMap(errorResponse)

        guard case .unknown(let statusCode, _) = mapped else {
            Issue.record("Expected .unknown, got \(mapped)")
            return
        }
        #expect(statusCode == 400)
    }

    @Test func maps500ToUnknown() {
        let body = """
        {"message": "Internal Server Error"}
        """.data(using: .utf8)
        let errorResponse = OryClient.ErrorResponse.error(500, body, nil, StubError())
        let mapped = OryErrorMapper.flatMap(errorResponse)

        guard case .unknown(let statusCode, _) = mapped else {
            Issue.record("Expected .unknown, got \(mapped)")
            return
        }
        #expect(statusCode == 500)
    }

    @Test func mapsErrorResponseWithURLErrorUnderlyingToNetwork() {
        let errorResponse = OryClient.ErrorResponse.error(500, nil, nil, URLError(.timedOut))
        let mapped = OryErrorMapper.flatMap(errorResponse)

        guard case .network = mapped else {
            Issue.record("Expected .network for URLError underlying, got \(mapped)")
            return
        }
    }
}

@Suite("ValidationErrorMapper")
struct ValidationErrorMapperTests {

    @Test func mapsSessionAlreadyAvailable() {
        let json = """
        {"id": "session_already_available", "message": "Already logged in"}
        """.data(using: .utf8)!

        let mapped = ValidationErrorMapper.flatMap(json)

        guard case .sessionAlreadyAvailable = mapped else {
            Issue.record("Expected .sessionAlreadyAvailable, got \(mapped)")
            return
        }
    }

    @Test func fallsBackToUnknownForUnrecognizedBody() {
        let json = """
        {"something": "unexpected"}
        """.data(using: .utf8)!

        let mapped = ValidationErrorMapper.flatMap(json)

        guard case .unknown(let statusCode, _) = mapped else {
            Issue.record("Expected .unknown, got \(mapped)")
            return
        }
        #expect(statusCode == 400)
    }
}

@Suite("FlowExpiredErrorMapper")
struct FlowExpiredErrorMapperTests {

    @Test func mapsNilDataToFlowExpired() {
        let mapped = FlowExpiredErrorMapper.flatMap(nil as Data?)

        guard case .flowExpired(let newFlowId) = mapped else {
            Issue.record("Expected .flowExpired, got \(mapped)")
            return
        }
        #expect(newFlowId == nil)
    }

    @Test func mapsFlowReplacedWithNewId() {
        let json = """
        {"use_flow_id": "new-flow-123"}
        """.data(using: .utf8)!

        let mapped = FlowExpiredErrorMapper.flatMap(json)

        guard case .flowExpired(let newFlowId) = mapped else {
            Issue.record("Expected .flowExpired, got \(mapped)")
            return
        }
        #expect(newFlowId == "new-flow-123")
    }

    @Test func mapsGenericExpiredError() {
        let json = """
        {"id": "self_service_flow_expired", "message": "Flow expired"}
        """.data(using: .utf8)!

        let mapped = FlowExpiredErrorMapper.flatMap(json)

        guard case .flowExpired(let newFlowId) = mapped else {
            Issue.record("Expected .flowExpired, got \(mapped)")
            return
        }
        #expect(newFlowId == nil)
    }

    @Test func fallsBackToFlowExpiredForUnrecognizedBody() {
        let json = """
        {"random": "data"}
        """.data(using: .utf8)!

        let mapped = FlowExpiredErrorMapper.flatMap(json)

        guard case .flowExpired = mapped else {
            Issue.record("Expected .flowExpired, got \(mapped)")
            return
        }
    }
}
