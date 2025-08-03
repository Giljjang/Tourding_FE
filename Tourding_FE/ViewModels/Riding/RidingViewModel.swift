//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

final class RidingViewModel: ObservableObject {
    
    private let testRepository: TestRepositoryProtocol
    
    init(testRepository: TestRepositoryProtocol) {
        self.testRepository = testRepository
    }
    
    // 예시 코드 - 서버로부터 test list를 불러옴
    func getTestList() async -> [TestModel] {
        do {
            let tests = try await testRepository.getTest()
            return tests
            
        } catch {
            return []
        }
    } // getTestList func
}
