//
//  SpotAddViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/28/25.
//

import Foundation

final class SpotAddViewModel: ObservableObject {
    @Published var clickFliter: String = ""
    let tagFilter: [String] = ["전체","자연", "인문(문화/예술/역사)", "레포츠", "쇼핑", "음식", "숙박"]
    
    func matchImageName(for title: String)-> String {
        switch title {
        case "전체":
            return "icon_menu"
        case "자연":
            return "icon_nature"
        case "인문(문화/예술/역사)":
            return "icon_humanities"
        case "레포츠":
            return "icon_Leports"
        case "쇼핑":
            return "icon_shopping"
        case "음식":
            return "icon_food"
        case "숙박":
            return "icon_Accommodation"
        default:
            return "icon_menu"
        }
    } // : func
}
