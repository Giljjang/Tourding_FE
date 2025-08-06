//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation

final class RidingViewModel: ObservableObject {
    @Published var start: String = "한동대학교"
    @Published var end: String = "영남대학교"
}
