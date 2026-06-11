//
//  DebugSessionLogger.swift
//  Tourding_FE
//

import Foundation

enum DebugSessionLogger {
    private static let sessionId = "397c83"
    private static let ingestURL = URL(string: "http://127.0.0.1:7674/ingest/6e431614-3e1a-46d5-b5a7-96329d0dfb1e")!

    static func log(
        location: String,
        message: String,
        hypothesisId: String,
        data: [String: String] = [:],
        runId: String = "pre-fix"
    ) {
        var payload: [String: Any] = [
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

        guard JSONSerialization.isValidJSONObject(payload),
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
    }
}
