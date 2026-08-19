//
//  NetworkErrorClassificationTests.swift
//  Tourding_FETests
//
//  NetworkService는 "아는 에러 코드 목록"(NetworkErrorCode)에 있는 것만 throw하고
//  나머지는 그대로 통과시켜 본문을 디코딩했다. 429·504처럼 목록에 없는 코드는
//  decodingFailure로 둔갑해 앱이 에러 종류를 구분할 수 없었다.
//
//  또 URLSession.shared를 설정 없이 써 요청 타임아웃이 기본 60초였다.
//  라이딩 시작 오버레이가 터치를 흡수하는 동안 재시도 3회면 최악 3분이다.
//

import Foundation
import Testing
@testable import Tourding_FE

struct NetworkErrorClassificationTests {

    // MARK: - 2xx 판정

    @Test(arguments: [200, 201, 204, 299])
    func successStatusIsNotAnError(_ code: Int) {
        #expect(HTTPStatusValidator.error(for: code) == nil)
    }

    @Test func knownStatusKeepsItsServerDefinedCode() throws {
        let error = try #require(HTTPStatusValidator.error(for: 500))
        guard case .serverDefinedError(let code) = error else {
            Issue.record("serverDefinedError가 아님: \(error)")
            return
        }
        #expect(code == .internalServerError)
    }

    /// 목록에 없는 코드가 통과해 decodingFailure로 둔갑하던 구멍
    @Test(arguments: [429, 504, 418, 302])
    func unknownNonSuccessStatusStillFailsWithItsCode(_ code: Int) throws {
        let error = try #require(HTTPStatusValidator.error(for: code),
                                 "\(code)이 에러로 판정되지 않으면 본문 디코딩으로 흘러간다")
        guard case .invalidResponse(let statusCode) = error else {
            Issue.record("invalidResponse가 아님: \(error)")
            return
        }
        #expect(statusCode == code)
    }

    // MARK: - 재시도 가능 여부

    /// 일시적 실패 — 다시 걸면 될 수 있다
    @Test(arguments: [408, 429, 503])
    func transientStatusIsRetryable(_ code: Int) throws {
        let error = try #require(HTTPStatusValidator.error(for: code))
        #expect(error.isRetryable == true)
    }

    /// 서버 오류는 다시 걸어도 같은 답이 온다.
    /// 실측: /routes/path 500이 3회 연속 동일하게 반환됐다.
    @Test(arguments: [500, 502, 504])
    func serverFailureIsNotRetryable(_ code: Int) throws {
        let error = try #require(HTTPStatusValidator.error(for: code))
        #expect(error.isRetryable == false)
    }

    @Test(arguments: [400, 401, 403, 404])
    func clientErrorIsNotRetryable(_ code: Int) throws {
        let error = try #require(HTTPStatusValidator.error(for: code))
        #expect(error.isRetryable == false)
    }

    /// 네트워크 단절은 재시도 대상이다
    @Test func networkFailureIsRetryable() {
        let error = ErrorType.networkFailure(underlying: URLError(.timedOut))
        #expect(error.isRetryable == true)
    }

    // MARK: - 서버 에러 본문

    private func body(_ json: String) -> Data { Data(json.utf8) }

    /// AI 엔드포인트는 4xx 본문에 code/message를 실어 보낸다.
    /// 코드를 못 읽으면 "음성 인식 실패"와 "처리할 수 없는 요청"을 구분할 수 없다.
    @Test func parsesServerErrorCodeFromBody() throws {
        let error = try #require(HTTPStatusValidator.error(
            for: 400,
            body: body(#"{"code":"AI_STT_FAILED","message":"음성을 인식하지 못했습니다."}"#)
        ))

        guard case .serverError(let code, let message, let statusCode) = error else {
            Issue.record("serverError가 아님: \(error)")
            return
        }
        #expect(code == "AI_STT_FAILED")
        #expect(message == "음성을 인식하지 못했습니다.")
        #expect(statusCode == 400)
    }

    /// 본문이 없으면 기존 판정 그대로여야 한다
    @Test func fallsBackToStatusOnlyWhenBodyIsAbsent() throws {
        let error = try #require(HTTPStatusValidator.error(for: 500, body: nil))
        guard case .serverDefinedError(let code) = error else {
            Issue.record("serverDefinedError가 아님: \(error)")
            return
        }
        #expect(code == .internalServerError)
    }

    /// 형태가 다른 본문도 기존 판정으로 떨어져야 한다 — 파싱 실패가 새 실패가 되면 안 된다
    @Test func fallsBackWhenBodyIsNotServerError() throws {
        let error = try #require(HTTPStatusValidator.error(
            for: 500,
            body: body(#"{"timestamp":"2026-08-18T05:15:07","status":500,"path":"/routes"}"#)
        ))
        guard case .serverDefinedError = error else {
            Issue.record("serverDefinedError가 아님: \(error)")
            return
        }
    }

    /// 2xx는 본문이 무엇이든 에러가 아니다
    @Test func successIsNotAnErrorEvenWithBody() {
        #expect(HTTPStatusValidator.error(
            for: 200,
            body: body(#"{"code":"X","message":"y"}"#)
        ) == nil)
    }

    /// 재시도 판정은 상태코드 기준을 그대로 따른다
    @Test func serverErrorRetryabilityFollowsStatusCode() throws {
        let aiError = try #require(HTTPStatusValidator.error(
            for: 400, body: body(#"{"code":"AI_UNSUPPORTED_REQUEST","message":"m"}"#)))
        #expect(aiError.isRetryable == false, "AI 에러(4xx)는 다시 걸어도 같다")

        let transient = try #require(HTTPStatusValidator.error(
            for: 503, body: body(#"{"code":"X","message":"m"}"#)))
        #expect(transient.isRetryable == true, "503은 본문이 있어도 재시도 대상이다")
    }

    // MARK: - 타임아웃

    @Test func sessionUsesBoundedTimeouts() {
        let configuration = NetworkService.session.configuration
        #expect(configuration.timeoutIntervalForRequest == 20)
        #expect(configuration.timeoutIntervalForResource == 60)
    }
}
