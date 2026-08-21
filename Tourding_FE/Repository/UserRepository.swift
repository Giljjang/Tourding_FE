//
//  UserRepository.swift
//  Tourding_FE
//
//  Created by 유재혁 on 9/7/25.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {

    init() {}
    
    // MARK: - Async/Await 버전
    func createUser(_ request: CreateUserRequest) async throws -> CreateUserResponse {
        guard let url = URL(string: "\(BASE_URL)/user/create") else {
            throw ErrorType.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await NetworkService.session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorType.invalidResponse(statusCode: -1)
        }
        if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
            throw statusError
        }

        return try JSONDecoder().decode(CreateUserResponse.self, from: data)
    }

    func deleteUser(id: Int) async throws {
        guard let url = URL(string: "\(BASE_URL)/user/delete?id=\(id)") else {
            throw ErrorType.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")

        let (_, response) = try await NetworkService.session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorType.invalidResponse(statusCode: -1)
        }
        // 204 No Content 기대. 2xx면 성공으로 본다
        if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
            throw statusError
        }
    }
    func updateRidingProfile(userId: Int, request: UpdateRidingProfileRequest) async throws -> UserRidingProfileResponse {
        guard let url = URL(string: "\(BASE_URL)/user/\(userId)/riding-profile") else {
            throw ErrorType.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await NetworkService.session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorType.invalidResponse(statusCode: -1)
        }
        if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
            throw statusError
        }

        return try JSONDecoder().decode(UserRidingProfileResponse.self, from: data)
    }

    func getRidingProfile(userId: Int) async throws -> UserRidingProfileResponse {
        guard let url = URL(string: "\(BASE_URL)/user/\(userId)/riding-profile") else {
            throw ErrorType.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")

        let (data, response) = try await NetworkService.session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorType.invalidResponse(statusCode: -1)
        }
        if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
            throw statusError
        }

        return try JSONDecoder().decode(UserRidingProfileResponse.self, from: data)
    }

    func revokeUser(userId: Int, authorizationCode: String) async throws {
        guard let url = URL(string: "\(BASE_URL)/user/revoke?userId=\(userId)&authorizationCode=\(authorizationCode)") else {
            throw ErrorType.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")

        let (_, response) = try await NetworkService.session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorType.invalidResponse(statusCode: -1)
        }
        // 200 OK 기대. 2xx면 성공으로 본다
        if let statusError = HTTPStatusValidator.error(for: httpResponse.statusCode) {
            throw statusError
        }
    }
}
