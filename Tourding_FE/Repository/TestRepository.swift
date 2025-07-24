//
//  TestRepository.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

// 테스트 레파지토리 - 실제 사용X
final class TestRepository: TestRepositoryProtocol {
    
    public init(){}
    
    func getTest() async throws -> [TestModel] {
        do {
            let response: [TestModel] = try await NetworkService.request(endpoint: "")
            return response
            
        } catch{
            print("Error: \(error.localizedDescription)")
            throw error
        }
    } // getTest func
}
