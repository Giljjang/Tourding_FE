//
//  UserService.swift
//  Tourding_FE
//
//  Created by 유재혁 on 9/6/25.
//

import Foundation

class UserService {
    static let shared = UserService()
    private init() {}
    
    // MARK: - 유저 등록
    func createUser(username: String, email: String, completion: @escaping (Result<CreateUserResponse, Error>) -> Void) {
        let request = CreateUserRequest(username: username, email: email)
        
        guard let url = URL(string: "\(BASE_URL)/user/create") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(CreateUserResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 유저 삭제
    func deleteUser(userId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(BASE_URL)/user/delete?id=\(userId)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // 204 No Content는 성공적인 삭제를 의미
            guard httpResponse.statusCode == 204 else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
}

// MARK: - 네트워크 에러 정의
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .noData:
            return "데이터가 없습니다."
        case .serverError(let code):
            return "서버 오류: \(code)"
        }
    }
}
