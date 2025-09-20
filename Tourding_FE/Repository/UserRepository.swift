//
//  UserRepository.swift
//  Tourding_FE
//
//  Created by 유재혁 on 9/7/25.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {

    static let shared = UserRepository()
    
    private init() {}
    
    // MARK: - Async/Await 버전
    func createUser(_ request: CreateUserRequest) async throws -> CreateUserResponse {
        guard let url = URL(string: "\(BASE_URL)/user/create") else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(CreateUserResponse.self, from: data)
    }

    func deleteUser(id: Int) async throws {
        guard let url = URL(string: "\(BASE_URL)/user/delete?id=\(id)") else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        // 204 No Content 기대
        guard httpResponse.statusCode == 204 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
    func revokeUser(userId: Int, authorizationCode: String) async throws {
        guard let url = URL(string: "\(BASE_URL)/user/revoke?userId=\(userId)&authorizationCode=\(authorizationCode)") else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        // 200 OK 기대
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - 네트워크 에러
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "유효하지 않은 URL입니다."
        case .invalidResponse: return "유효하지 않은 응답입니다."
        case .noData: return "데이터가 없습니다."
        case .serverError(let code): return "서버 오류: \(code)"
        }
    }
}
