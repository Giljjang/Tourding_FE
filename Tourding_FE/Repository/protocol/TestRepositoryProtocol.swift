//
//  TestRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import Foundation

// 테스트 레파지토리 프로토콜 - 실제 사용X
protocol TestRepositoryProtocol {
    func getTest() async throws -> [TestModel] 
}
