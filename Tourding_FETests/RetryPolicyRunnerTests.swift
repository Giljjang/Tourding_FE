//
//  RetryPolicyRunnerTests.swift
//  Tourding_FETests
//
//  D6 — 재시도 루프가 4곳에 복붙돼 있다.
//
//  가드는 네 곳 다 들어가 있지만, 같은 코드가 흩어져 있으면 다섯 번째 루프에서 빠뜨린다.
//  실제로 `ErrorType.isRetryable` 가드가 없던 시절 이 서버의 500에 3회씩 재시도하며
//  이미 무너진 서버를 더 밀어붙였다 (실측: /routes/path 500이 3회 연속 동일한 답).
//
//  정책을 한 곳으로 모으고 여기서 계약을 잠근다.
//  (기존 `RetryPolicyTests`는 ViewModel 레벨에서 "500에 재시도하지 않는다"를 잠근다.
//   이 파일은 그 아래의 정책 엔진 자체를 다룬다.)
//

import Foundation
import Testing
@testable import Tourding_FE

struct RetryPolicyRunnerTests {

    /// 일시적 네트워크 장애를 흉내내는 더미 (`ErrorType.networkFailure`는 `isRetryable == true`)
    private struct Transient: Error {}

    /// 호출 횟수를 세는 상자. 클로저가 값을 바꿔야 해서 참조 타입이 필요하다.
    private final class CallCounter: @unchecked Sendable {
        var count = 0
    }

    // MARK: - 성공

    @Test func successReturnsImmediatelyWithoutRetry() async {
        let counter = CallCounter()

        let result = await RetryPolicy.run(delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            return 42
        }

        #expect(result == 42)
        #expect(counter.count == 1, "성공하면 다시 걸지 않는다")
    }

    /// 중간에 성공하면 남은 시도를 소비하지 않는다
    @Test func stopsAtFirstSuccess() async {
        let counter = CallCounter()

        let result = await RetryPolicy.run(maxAttempts: 5, delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            if counter.count < 3 { throw ErrorType.networkFailure(underlying: Transient()) }
            return "ok"
        }

        #expect(result == "ok")
        #expect(counter.count == 3)
    }

    // MARK: - 재시도 판정

    /// 일시적 에러는 maxAttempts까지 다시 건다
    @Test func retriesTransientErrorUpToMaxAttempts() async {
        let counter = CallCounter()

        let result: Int? = await RetryPolicy.run(maxAttempts: 3, delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            throw ErrorType.networkFailure(underlying: Transient())
        }

        #expect(result == nil)
        #expect(counter.count == 3)
    }

    /// **핵심** — 500은 다시 걸어도 같은 답이 온다. 한 번만 시도하고 중단해야 한다
    @Test func doesNotRetryServerError() async {
        let counter = CallCounter()

        let result: Int? = await RetryPolicy.run(maxAttempts: 3, delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            throw ErrorType.serverDefinedError(.internalServerError)
        }

        #expect(result == nil)
        #expect(counter.count == 1, "재시도 불가 에러는 한 번만 시도한다")
    }

    /// 4xx도 마찬가지다 — 요청이 잘못된 것이라 다시 걸어도 같다
    @Test func doesNotRetryClientError() async {
        let counter = CallCounter()

        let result: Int? = await RetryPolicy.run(maxAttempts: 3, delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            throw ErrorType.serverDefinedError(.badRequest)
        }

        #expect(result == nil)
        #expect(counter.count == 1)
    }

    /// `ErrorType`이 아닌 에러는 판정할 수 없으므로 재시도한다 (기존 동작 유지)
    @Test func retriesUnknownErrorType() async {
        struct Unknown: Error {}
        let counter = CallCounter()

        let result: Int? = await RetryPolicy.run(maxAttempts: 2, delayNanoseconds: 0, label: "테스트") {
            counter.count += 1
            throw Unknown()
        }

        #expect(result == nil)
        #expect(counter.count == 2)
    }
}
