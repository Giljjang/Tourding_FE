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

    // MARK: - 타임아웃

    @Test func sessionUsesBoundedTimeouts() {
        let configuration = NetworkService.session.configuration
        #expect(configuration.timeoutIntervalForRequest == 20)
        #expect(configuration.timeoutIntervalForResource == 60)
    }
}
