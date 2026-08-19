//
//  NetworkService.swift
//  Tourding_FE
//
//  Created by 이유현 on 3/3/25.
//

import Foundation

enum NetworkService {

    /// 타임아웃을 건 전용 세션.
    ///
    /// URLSession.shared는 요청 60초·리소스 7일이 기본이다. 라이딩 시작 오버레이가
    /// 터치를 흡수하는 동안 재시도까지 겹치면 화면이 수 분간 잠긴다.
    /// 20초 근거: 가장 무거운 /routes(80KB대, ORS 전체 재계산)가 실측 1~3초에 끝난다.
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    // #region agent log
    private static var searchLocationRequestSeq = 0
    private static let searchLocationSeqLock = NSLock()

    private static func nextSearchLocationSeq() -> Int {
        searchLocationSeqLock.lock()
        defer { searchLocationSeqLock.unlock() }
        searchLocationRequestSeq += 1
        return searchLocationRequestSeq
    }

    private static func debugLogSearchLocation(
        phase: String,
        url: URL,
        method: String,
        seq: Int,
        request: URLRequest? = nil,
        statusCode: Int? = nil,
        responseSnippet: String? = nil,
        hypothesisId: String
    ) {
        guard url.absoluteString.contains("search-location") else { return }

        var data: [String: String] = [
            "seq": String(seq),
            "phase": phase,
            "url": url.absoluteString,
            "method": method
        ]

        if let request {
            let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
            let headers = request.allHTTPHeaderFields?
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: "; ") ?? "none"
            data["body"] = body
            data["headers"] = headers
            data["hasAcceptHeader"] = String(request.value(forHTTPHeaderField: "Accept") != nil)
        }

        if let statusCode {
            data["statusCode"] = String(statusCode)
        }
        if let responseSnippet {
            data["responseSnippet"] = String(responseSnippet.prefix(300))
        }

        DebugSessionLogger.log(
            location: "NetworkService.swift:requestToServer",
            message: "search-location \(phase)",
            hypothesisId: hypothesisId,
            data: data
        )
    }
    // #endregion
    
    // API 타입 정의
    enum APIType {
        case main           // 기존 BASE_URL
        case kakaoLocal     // 카카오 로컬 API
        case custom(String) // 커스텀 URL
    }
    
    // baseUrl 설정
    enum RequestURL {
        static var baseURL: String {
            return BASE_URL
        }
        
        static var localURL: String {
            return "http..."
        }
        
        static var kakaoURL: String {
            return Bundle.main.infoDictionary?["KAKAO_URL"] as? String ?? "https://dapi.kakao.com"
        }
        
        // API 타입에 따른 URL 반환
        static func getURL(for apiType: APIType) -> String {
            switch apiType {
            case .main:
                return baseURL
            case .kakaoLocal:
                return kakaoURL
            case .custom(let url):
                return url
            }
        }
    }
    
    //MARK: - HTTP 메소드 요청 (개선된 버전 - APIType 사용)
    static func request<T: Codable>(
        apiType: APIType,
        endpoint: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Codable? = nil,
        method: String = "GET"
    ) async throws -> T {
        let baseURL = RequestURL.getURL(for: apiType)
        let destination = try makeURL(url: baseURL, endpoint: endpoint, parameters: parameters)
        return try await requestToServer(url: destination, method: method, body: body, headers: headers)
    }
    
    //MARK: - URL 생성
    private static func makeURL(url: String,
                                endpoint: String,
                                parameters: [String: String]? = nil) throws -> URL {
        
        var urlString = url + endpoint
        
        if let parameters = parameters {
            let queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            var components = URLComponents(string: urlString)!
            components.queryItems = queryItems
            urlString = components.url?.absoluteString ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            throw ErrorType.invalidURL
        }
        
        return url
    }
    
    //MARK: - 네트워크 요청 메서드 (헤더 지원 추가)
    private static func requestToServer<T: Codable>(
        url: URL,
        method: String = "GET",
        body: Codable? = nil,
        headers: [String: String]? = nil) async throws -> T {
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            
            // 헤더 설정
            if let headers = headers {
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            // body가 있을 경우 JSON 형태로 인코딩해서 추가
            if let body = body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    print("Error encoding body: \(error)")
                    throw error
                }
            }
            
            // 네트워크 요청 실행
            print("🔵 네트워크 요청 시작: \(request.url?.absoluteString ?? "URL 없음")")
            print("🔵 HTTP Method: \(request.httpMethod ?? "GET")")
            if let body = request.httpBody {
                print("🔵 Request Body: \(String(data: body, encoding: .utf8) ?? "디코딩 실패")")
            }

            // #region agent log
            let debugSeq = request.url?.absoluteString.contains("search-location") == true
                ? nextSearchLocationSeq()
                : 0
            if let requestURL = request.url, debugSeq > 0 {
                debugLogSearchLocation(
                    phase: "request",
                    url: requestURL,
                    method: request.httpMethod ?? "GET",
                    seq: debugSeq,
                    request: request,
                    hypothesisId: "A_B_E"
                )
            }
            // #endregion
            
            let data: Data
            let response: URLResponse
            
           (data, response) = try await session.data(for: request)
           
           print("🔵 네트워크 응답 받음")
           if let httpResponse = response as? HTTPURLResponse {
               print("🔵 HTTP Status Code: \(httpResponse.statusCode)")
           }

            // #region agent log
            if let requestURL = request.url, debugSeq > 0 {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let snippet = String(data: data, encoding: .utf8) ?? ""
                debugLogSearchLocation(
                    phase: "response",
                    url: requestURL,
                    method: request.httpMethod ?? "GET",
                    seq: debugSeq,
                    statusCode: status,
                    responseSnippet: snippet,
                    hypothesisId: status >= 400 ? "F" : "F_ok"
                )
            }
            // #endregion
            if let httpResponse = response as? HTTPURLResponse,
               let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode, body: data) {
                print("HTTP \(httpResponse.statusCode) body:",
                      String(data: data, encoding: .utf8) ?? "<no body>")
                throw statusError
            }
            
            do {
                // 네트워크 요청 후 서버로부터 받은 데이터를 디코딩
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                throw ErrorType.decodingFailure(underlying: error)
            }
        }
}

//MARK: - HTTP 상태 판정

/// 서버가 4xx 본문에 실어 보내는 에러. AI 엔드포인트가 이 형태를 쓴다.
/// 예: {"code":"AI_STT_FAILED","message":"음성을 인식하지 못했습니다."}
struct ServerErrorBody: Decodable {
    let code: String
    let message: String
}

/// 상태코드 → 에러 판정. URLSession 없이 테스트할 수 있도록 순수 함수로 분리한다.
enum HTTPStatusValidator {
    static func error(for statusCode: Int, body: Data? = nil) -> ErrorType? {
        if (200..<300).contains(statusCode) { return nil }

        // 서버가 본문에 code/message를 실어 보냈으면 그걸 쓴다.
        // AI 엔드포인트는 이 형태로 실패 사유를 구분해준다
        // (AI_STT_FAILED / AI_UNSUPPORTED_REQUEST / ROUTE_SUMMARY_NOT_FOUND …).
        // 형태가 다르면(스프링 기본 에러 본문 등) 아래 기존 판정으로 떨어진다.
        if let body,
           let parsed = try? JSONDecoder().decode(ServerErrorBody.self, from: body) {
            return .serverError(code: parsed.code, message: parsed.message, statusCode: statusCode)
        }

        // 사용자 문구가 정의된 코드는 그대로 보존한다
        if let known = NetworkErrorCode(rawValue: statusCode) {
            return .serverDefinedError(known)
        }

        // 목록에 없는 코드(429·504 등)를 통과시키면 본문 디코딩으로 흘러가
        // decodingFailure로 둔갑한다. 코드를 그대로 실어 올린다.
        return .invalidResponse(statusCode: statusCode)
    }
}

//MARK: - Error 처리
enum NetworkErrorCode: Int {
    case idNotFoundError = 301
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalServerError = 500
    case notImplement = 501
    case badGateway = 502
    case serviceUnavailable = 503
    
    var showErrorDescription: String {
        switch self {
        case .idNotFoundError:
            return "301: 요청한 ID를 찾을 수 없습니다."
        case .badRequest:
            return "400: 잘못된 요청입니다."
        case .unauthorized:
            return "401: 요청에 필요한 권한이 없습니다."
        case .forbidden:
            return "403: 접근이 금지되었습니다."
        case .notFound:
            return "404: 리소스를 찾을 수 없습니다."
        case .internalServerError:
            return "500: 서버에 에러가 발생하였습니다."
        case .notImplement:
            return "요청한 사항을 서버에서 실행할 수 없습니다."
        case .badGateway:
            return "게이트웨이 에러"
        case .serviceUnavailable:
            return "서버 점검 중"
        }
    }
}

enum ErrorType: Error {
    /// 다시 걸면 될 수 있는 실패인가.
    ///
    /// 이 서버의 500은 결정적이다 — 실측상 /routes/path 500이 3회 연속 같은 답을 받았다.
    /// 재시도는 낭비이고, 이미 무너진 서버를 더 밀어붙인다.
    var isRetryable: Bool {
        switch self {
        case .networkFailure:
            return true
        case .serverDefinedError(let code):
            return code == .serviceUnavailable          // 503만
        case .invalidResponse(let statusCode):
            return statusCode == 408 || statusCode == 429
        case .serverError(_, _, let statusCode):
            // 본문이 있어도 재시도 여부는 상태코드가 정한다
            return statusCode == 408 || statusCode == 429 || statusCode == 503
        case .invalidURL, .decodingFailure, .unknown:
            return false
        }
    }

    case invalidURL
    case networkFailure(underlying: Error)
    case invalidResponse(statusCode: Int)
    case decodingFailure(underlying: Error)
    case unknown(underlying: Error)
    case serverDefinedError(NetworkErrorCode)
    /// 서버가 본문에 code/message를 실어 보낸 에러 (AI 엔드포인트 등)
    case serverError(code: String, message: String, statusCode: Int)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .networkFailure(let err):
            return "A network error occurred: \(err.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Invalid response from server with status code \(statusCode)."
        case .decodingFailure:
            return "Failed to decode the response."
        case .unknown(let err):
            return "An unknown error occurred: \(err.localizedDescription)"
        case .serverDefinedError(let code):
            return code.showErrorDescription
        case .serverError(_, let message, _):
            return message
        }
    }
}

// MARK: - 다운로드 전용 요청 (대용량 데이터)
extension NetworkService {
    
    // 대용량 요청용 downloadTask
    static func downloadRequest<T: Codable>(
        apiType: APIType,
        endpoint: String,
        method: String = "GET",
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Codable? = nil
    ) async throws -> T {
        
        let baseURL = RequestURL.getURL(for: apiType)
        let destination = try makeURL(url: baseURL, endpoint: endpoint, parameters: parameters)
        
        return try await downloadFromServer(
            url: destination,
            method: method,
            headers: headers,
            body: body
        )
    }
    private static func downloadFromServer<T: Codable>(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Codable? = nil
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // 헤더 설정
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // body가 있으면 JSON으로 인코딩
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            
            // 디버깅: body 출력
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
//                print("🔹 Request Body:\n\(jsonString)")
            }
        }
        
        // downloadTask 실행
        let (tempURL, response) = try await session.download(for: request)
        
        // HTTP 상태 코드 체크
        if let httpResponse = response as? HTTPURLResponse {
            print("🔹 HTTP Status Code: \(httpResponse.statusCode)")
            
            if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
                throw statusError
            }
        }
        
        // 임시 파일 읽기
        let data = try Data(contentsOf: tempURL)
        
        // 디버깅: 서버에서 내려온 원본 데이터 출력
        if let jsonString = String(data: data, encoding: .utf8) {
//            print("🔹 Response Data:\n\(jsonString)")
        } else {
            print("🔹 Response Data: Cannot convert to string")
        }
        
        // JSON 디코딩
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            print("❌ Decoding error: \(error)")
            throw ErrorType.decodingFailure(underlying: error)
        }
    }

}

