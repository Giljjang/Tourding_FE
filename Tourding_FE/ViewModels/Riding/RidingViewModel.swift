//
//  RidingViewModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/5/25.
//

import Foundation
import Combine
import NMapsMap

final class RidingViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var flag: Bool = false // 라이딩 전 <-> 라이딩 후 화면 변경
    
    //라이딩 시작 전
    @Published var start: RidingSpotModel = RidingSpotModel(name: "출발지")
    @Published var end: RidingSpotModel = RidingSpotModel(name: "도착지")
    @Published var spotList: [RidingSpotModel]  = []
    @Published var nthLineHeight: Double = 0 // spotRow 왼쪽 라인 길이
    
    // 라이딩 시작 후
    @Published var showToilet: Bool = false
    @Published var showConvenienceStore: Bool = false
    @Published var guideList: [GuideModel] = []
    
    // MARK: - 지도 관련 프로퍼티
    var locationManager: LocationManager?
    var mapView: NMFMapView?
    
    
    // MARK: - 지도 관련 프로퍼티
    @Published var pathCoordinates: [NMGLatLng] = [
        NMGLatLng(lat: 37.5665, lng: 126.9780),
        NMGLatLng(lat: 35.1796, lng: 129.0756),
        NMGLatLng(lat: 35.9078, lng: 127.7669),
        NMGLatLng(lat: 37.4563, lng: 126.7052)
    ]
    
    // 특정 좌표에 marker 넣기
    @Published var markerCoordinates: [NMGLatLng] = [
        NMGLatLng(lat: 37.5665, lng: 126.9780),  // 첫 번째 위치
        NMGLatLng(lat: 35.9078, lng: 127.7669)   // 세 번째 위치
    ]
    @Published var markerIcons: [NMFOverlayImage] = [
        MarkerIcons.goalMarker,
        MarkerIcons.startMarker
    ]
    
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
        
        // flag 변경 감지
        $flag
            .sink { [weak self] newValue in
                print("flag 변경됨: \(newValue)")
            }
            .store(in: &cancellables)
    }
    
    //MARK: - mock
    private func showMockSpotList(){
        let mock1 = RidingSpotModel(name: "태화강공원", themeType: .humanities)
        let mock2 = RidingSpotModel(name: "어딘가.. 맛있는 곳", themeType: .food)
        
        spotList.insert(contentsOf: [mock1, mock2], at: 0)
        
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

