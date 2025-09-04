//
//  RidingViewModel+LocationTracking.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation
import NMapsMap


//MARK: - 사용자 위치 추적 및 업데이트
extension RidingViewModel {
    // 사용자 위치 업데이트 시 호출하여 지나간 마커 확인 및 제거
    func updateUserLocationAndCheckMarkers(_ newLocation: NMGLatLng) {
        // 라이딩 중일 때만 마커 추적
        guard flag else { return }
        
        currentUserLocation = newLocation
        checkAndRemovePassedMarkers()
    }
    
    // 지나간 마커를 확인하고 제거
    private func checkAndRemovePassedMarkers() {
        guard let userLocation = currentUserLocation else { return }
        
        // 기존 마커들 확인
        var indicesToRemove: [Int] = []
        
        for (index, markerCoord) in markerCoordinates.enumerated() {
            let distance = calculateDistance(from: userLocation, to: markerCoord)
            if distance <= markerPassThreshold {
                indicesToRemove.append(index)
            }
        }
        
        // 지나간 마커들 제거 (역순으로 제거하여 인덱스 변화 방지)
        for index in indicesToRemove.reversed() {
            if index < markerCoordinates.count {
                markerCoordinates.remove(at: index)
            }
            if index < markerIcons.count {
                markerIcons.remove(at: index)
            }
        }
        
        // 가이드 리스트에서도 제거
        if !indicesToRemove.isEmpty {
            for index in indicesToRemove.reversed() {
                if index < guideList.count {
                    guideList.remove(at: index)
                }
            }
        }
        
        // 디버깅용 로그
        if !indicesToRemove.isEmpty {
            print("지나간 마커 \(indicesToRemove.count)개 제거됨")
            print("남은 마커: \(markerCoordinates.count)개")
        }
    }
    
    // 두 좌표 간의 거리 계산 (미터 단위)
    private func calculateDistance(from: NMGLatLng, to: NMGLatLng) -> Double {
        let lat1 = from.lat * .pi / 180
        let lat2 = to.lat * .pi / 180
        let deltaLat = (to.lat - from.lat) * .pi / 180
        let deltaLng = (to.lng - from.lng) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLng/2) * sin(deltaLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        // 지구 반지름 (미터)
        let earthRadius: Double = 6371000
        
        return earthRadius * c
    }
    
    // 특정 마커가 사용자 위치 근처에 있는지 확인
    func isMarkerNearUser(_ markerCoord: NMGLatLng) -> Bool {
        guard let userLocation = currentUserLocation else { return false }
        let distance = calculateDistance(from: userLocation, to: markerCoord)
        return distance <= markerPassThreshold
    }

}
