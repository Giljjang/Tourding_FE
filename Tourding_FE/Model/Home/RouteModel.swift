//
//  RouteModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/17/25.
//

import Foundation

// MARK: - 위치 데이터 모델 (순수 데이터)
struct LocationData {
    let name: String
    let latitude: Double
    let longitude: Double
    
    init(name: String = "", latitude: Double = 0.0, longitude: Double = 0.0) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - 루트 데이터 모델 (순수 데이터)
struct RouteData {
    let startLocation: LocationData
    let endLocation: LocationData
    
    init(startLocation: LocationData = LocationData(), endLocation: LocationData = LocationData()) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
}

// MARK: - 위치 선택 모드
enum LocationSelectionMode {
    case none
    case startLocation
    case endLocation
}

// MARK: - Place 모델을 LocationData로 변환하는 확장
extension LocationData {
    init(from place: Place) {
        self.name = place.placeName
        self.latitude = place.latitude
        self.longitude = place.longitude
    }
    
    // MARK: - 계산 프로퍼티 (데이터 상태 확인용)
    var isEmpty: Bool {
        return name.isEmpty
    }
    
    var isValid: Bool {
        return !name.isEmpty && latitude != 0.0 && longitude != 0.0
    }
}

// MARK: - RouteData 계산 프로퍼티 확장
extension RouteData {
    var isComplete: Bool {
        return startLocation.isValid && endLocation.isValid
    }
    
    var hasStartLocation: Bool {
        return startLocation.isValid
    }
    
    var hasEndLocation: Bool {
        return endLocation.isValid
    }
}
