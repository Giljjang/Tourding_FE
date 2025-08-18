////
////  RouteLocationManager.swift
////  Tourding_FE
////
////  Created by 유재혁 on 8/17/25.
////
//  앱 전체에서 페이지 간 검색 데이터를 공유하고 관리하는 전용 매니저

import Foundation

final class RouteSharedManager: ObservableObject {
    
    // MARK: - 라우트 데이터
    @Published var routeData = RouteData()
    
    // MARK: - 현재 선택 모드
    @Published var currentSelectionMode: LocationSelectionMode = .none
    
    // MARK: - 위치 설정 메서드들
    func setStartLocation(from place: Place) {
        let location = LocationData(from: place)
        routeData = RouteData(startLocation: location, endLocation: routeData.endLocation)
        
        print("✅ 출발지 설정됨:")
        print("   장소명: \(location.name)")
        print("   위도: \(location.latitude)")
        print("   경도: \(location.longitude)")
    }
    
    func setEndLocation(from place: Place) {
        let location = LocationData(from: place)
        routeData = RouteData(startLocation: routeData.startLocation, endLocation: location)
        
        print("✅ 도착지 설정됨:")
        print("   장소명: \(location.name)")
        print("   위도: \(location.latitude)")
        print("   경도: \(location.longitude)")
    }
    
    func setLocation(from place: Place) {
        switch currentSelectionMode {
        case .startLocation:
            setStartLocation(from: place)
        case .endLocation:
            setEndLocation(from: place)
        case .none:
            print("⚠️ 선택 모드가 설정되지 않았습니다.")
        }
        
        // 설정 후 모드 초기화
        currentSelectionMode = .none
    }
    
    // MARK: - 데이터 초기화 메서드들
    func clearStartLocation() {
        routeData = RouteData(startLocation: LocationData(), endLocation: routeData.endLocation)
        print("🗑️ 출발지 초기화됨")
    }
    
    func clearEndLocation() {
        routeData = RouteData(startLocation: routeData.startLocation, endLocation: LocationData())
        print("🗑️ 도착지 초기화됨")
    }
    
    func clearRoute() {
        routeData = RouteData()
        currentSelectionMode = .none
        print("🗑️ 모든 루트 데이터 초기화됨")
    }
    
    // MARK: - 유틸리티 메서드들
    var hasValidPoints: Bool {
        return routeData.isComplete
    }
    
    var hasStartLocation: Bool {
        return routeData.hasStartLocation
    }
    
    var hasEndLocation: Bool {
        return routeData.hasEndLocation
    }
    
    func printCurrentRouteState() {
        print("📍 현재 루트 상태:")
        print("   출발지: \(routeData.startLocation.name) (\(routeData.startLocation.latitude), \(routeData.startLocation.longitude))")
        print("   도착지: \(routeData.endLocation.name) (\(routeData.endLocation.latitude), \(routeData.endLocation.longitude))")
        print("   선택 모드: \(currentSelectionMode)")
        print("   완성 여부: \(routeData.isComplete)")
    }
}
