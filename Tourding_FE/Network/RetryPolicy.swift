//
//  RetryPolicy.swift
//  Tourding_FE
//
//  재시도 정책 단일 지점.
//
//  같은 루프가 ViewModel 4곳에 복붙돼 있었다. 가드는 네 곳 다 들어가 있었지만,
//  흩어져 있으면 다섯 번째 루프에서 빠뜨린다 — 실제로 `isRetryable` 가드가 없던 시절
//  이 서버의 500에 3회씩 재시도하며 이미 무너진 서버를 더 밀어붙였다
//  (실측: `/routes/path` 500이 3회 연속 동일한 답).
//

import Foundation

enum RetryPolicy {

    static let defaultMaxAttempts = 3
    static let defaultDelayNanoseconds: UInt64 = 1_000_000_000

    /// 재시도 가능한 실패에만 다시 건다.
    ///
    /// 500·502·504·4xx는 다시 걸어도 같은 답이 오므로 즉시 중단한다 (`ErrorType.isRetryable`).
    /// `ErrorType`이 아닌 에러는 판정할 수 없으므로 재시도한다.
    ///
    /// - Returns: 성공한 결과. 최종 실패하거나 재시도 불가 에러면 `nil`.
    static func run<T>(
        maxAttempts: Int = defaultMaxAttempts,
        delayNanoseconds: UInt64 = defaultDelayNanoseconds,
        label: String,
        operation: () async throws -> T
    ) async -> T? {
        var attempt = 0

        while attempt < maxAttempts {
            do {
                return try await operation()
            } catch {
                guard (error as? ErrorType)?.isRetryable ?? true else {
                    print("🚫 \(label) — 재시도하지 않는 에러, 중단: \(error)")
                    return nil
                }

                attempt += 1
                print("❌ \(label) 실패 (시도 \(attempt)/\(maxAttempts)): \(error)")

                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: delayNanoseconds)
                } else {
                    print("❌ \(label) 최종 실패")
                }
            }
        }

        return nil
    }
}
