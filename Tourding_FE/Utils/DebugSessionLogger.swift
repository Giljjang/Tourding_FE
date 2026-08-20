//
//  DebugSessionLogger.swift
//  Tourding_FE
//

import Foundation

/// 에이전트 디버깅용 임시 계측기.
///
/// 릴리즈 빌드에서는 본문 전체가 컴파일되지 않는다(no-op).
/// 이전에는 `#if DEBUG`가 없어 실제 앱에서도 요청 헤더·바디·좌표가
/// 하드코딩된 loopback 주소로 전송되고 디바이스 콘솔에 평문으로 남았다.
///
/// 이 로거와 `// #region agent log` 블록들은 디버깅이 끝나면 제거 대상이다.
/// 새 코드(특히 AI 경로)에는 추가하지 말 것.
enum DebugSessionLogger {
    #if DEBUG
    private static let sessionId = "397c83"
    private static let ingestURL = URL(string: "http://127.0.0.1:7674/ingest/6e431614-3e1a-46d5-b5a7-96329d0dfb1e")!

    /// 수집 서버가 떠 있을 때만 켠다.
    /// 꺼져 있으면 요청마다 연결 거부 + nw_* 로그가 15줄씩 쏟아져 콘솔을 못 읽는다.
    private static let isIngestEnabled = false
    #endif

    static func log(
        location: String,
        message: String,
        hypothesisId: String,
        data: [String: String] = [:],
        runId: String = "pre-fix"
    ) {
        #if DEBUG
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": location,
            "message": message,
            "hypothesisId": hypothesisId,
            "runId": runId,
            "data": data
        ]

        // #region agent log
        print("[DEBUG-397c83][\(hypothesisId)] \(message) | \(data)")

        guard isIngestEnabled,
              JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        var request = URLRequest(url: ingestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request).resume()
        // #endregion
        #endif
    }
}
