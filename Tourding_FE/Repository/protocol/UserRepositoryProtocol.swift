//
//  UserRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 유재혁 on 9/7/25.
//

import Foundation


protocol UserRepositoryProtocol {
    func createUser(_ request: CreateUserRequest) async throws -> CreateUserResponse
    func deleteUser(id: Int) async throws
    func revokeUser(userId: Int, authorizationCode: String) async throws
}
