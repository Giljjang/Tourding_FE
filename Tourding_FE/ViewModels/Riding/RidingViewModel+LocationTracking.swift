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
        
        // 이전 위치와 비교하여 위치가 실제로 변경되었는지 확인
        let hasLocationChanged = currentUserLocation == nil || 
                                calculateDistance(from: currentUserLocation!, to: newLocation) > 5.0 // 5미터 이상 변경시에만
        
        currentUserLocation = newLocation
        
        // 위치가 변경되었을 때만 마커 체크 및 카메라 업데이트
        if hasLocationChanged {
            checkAndRemovePassedMarkers()
            updateCameraToUserLocation()
        }
    }
    
    // 지나간 마커를 확인하고 제거 (특정 좌표를 지나가면 그 이전의 모든 좌표들 제거)
    private func checkAndRemovePassedMarkers() {
        guard let userLocation = currentUserLocation else { return }
        
        // 가장 가까운 마커의 인덱스 찾기
        var closestMarkerIndex: Int? = nil
        var minDistance = Double.infinity
        
        for (index, markerCoord) in markerCoordinates.enumerated() {
            let distance = calculateDistance(from: userLocation, to: markerCoord)
            if distance <= markerPassThreshold && distance < minDistance {
                minDistance = distance
                closestMarkerIndex = index
            }
        }
        
        // 가장 가까운 마커를 지나갔다면, 그 마커 이전의 모든 마커들 제거
        if let closestIndex = closestMarkerIndex {
            let removedCount = closestIndex + 1
            
            // 마커 좌표와 아이콘에서 제거 (0부터 closestIndex까지)
            markerCoordinates.removeFirst(removedCount)
            markerIcons.removeFirst(removedCount)
            
            // 가이드 리스트에서도 제거
            if removedCount <= guideList.count {
                guideList.removeFirst(removedCount)
            }
            
            // 경로 좌표에서도 제거 (경로선 업데이트)
            if removedCount <= pathCoordinates.count {
                pathCoordinates.removeFirst(removedCount)
            }
            
            // 실제 지도에서 마커 업데이트
            updateMarkersOnMap()
            
            // 디버깅용 로그
            print("지나간 마커 \(removedCount)개 제거됨 (인덱스 0~\(closestIndex))")
            print("남은 마커: \(markerCoordinates.count)개")
            print("남은 경로 좌표: \(pathCoordinates.count)개")
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
    
    // 사용자 위치로 카메라 업데이트
    private func updateCameraToUserLocation() {
        guard let userLocation = currentUserLocation,
              let mapView = mapView else { return }
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: userLocation)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // x: 0.5(가로 중앙), y: 0.3(세로 위쪽)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        print("카메라가 사용자 위치로 업데이트됨: \(userLocation.lat), \(userLocation.lng)")
    }
    
    // 지도에서 마커 업데이트
    private func updateMarkersOnMap() {
        guard let markerManager = markerManager else { return }
        
        // 기존 마커들을 모두 제거하고 새로운 마커들로 업데이트
        markerManager.clearMarkers()
        markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
        
        print("지도에서 마커 업데이트 완료: \(markerCoordinates.count)개")
    }

}
