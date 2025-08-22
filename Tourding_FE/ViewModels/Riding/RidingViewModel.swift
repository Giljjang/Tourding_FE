//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
import Combine

enum RidingMode {
    case beforeStart
    case afterStart
}

final class RidingViewModel: ObservableObject {
    @Published var ridingMode: RidingMode = .beforeStart // 바텀 시트 콘텐츠 타입
    @Published var isLoading: Bool = true // 데이터 불러올 때까지 로딩 표시
    
    @Published var start: String = "한동대학교"
    @Published var end: String = "영남대학교"
    @Published var spotList: [RidingSpotModel]  = []
    
    @Published var showToilet: Bool = false
    @Published var showConvenienceStore: Bool = false
    @Published var guideList: [GuideModel] = []
    
    
    @Published var nthLineHeight: Double = 0 // spotRow 왼쪽 라인 길이
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        showMockSpotList()
        showMockGuideList()
        
        // spotList 변경 감지 후 nthLineHeight 계산
        $spotList
            .sink { [weak self] _ in
                self?.calculateNthLineHeight()
            }
            .store(in: &cancellables)
    }
    
    //MARK: - mock
    private func showMockSpotList(){
        let mock1 = RidingSpotModel(name: "태화강공원", themeType: .humanities)
        let mock2 = RidingSpotModel(name: "어딘가.. 맛있는 곳", themeType: .food)
        
        spotList.append(contentsOf: [mock1, mock2])
        
    } // : func showMockSpotList
    
    private func showMockGuideList(){
        let mock1 = GuideModel(
            sequenceNum: 0,
            distance: 17,
            duration: 6119,
            instructions: "'희망대로659번길' 방면으로 우회전",
            pointIndex: 1,
            type: 3)
        let mock2 = GuideModel(
            sequenceNum: 1,
            distance: 475,
            duration: 157222,
            instructions: "'희망대로' 방면으로 우회전",
            pointIndex: 22,
            type: 3
        )
        
        guideList.append(contentsOf: [mock1, mock2])
    }
    
    //MARK: - util
    private func calculateNthLineHeight() {
        nthLineHeight = Double((spotList.count * 66) + (spotList.count + 1) * 8)
    } // : func calculateNthLineHeight
    
    //MARK: - 이 밑에부터 지도 함수
}

//MARK: -  Riding 시작하기 이후 라이딩 뷰 함수
extension RidingViewModel {
    func toggleToilet(){
        showToilet.toggle()
    }
    
    func toggleConvenienceStore(){
        showConvenienceStore.toggle()
    }
}

