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
        // 라이딩 중일 때만 마커 추적 및 카메라 업데이트
        guard flag else { 
            print("🚫 라이딩 중이 아니므로 위치 추적 중단")
            return 
        }
        
        // 이전 위치와 비교하여 위치가 실제로 변경되었는지 확인
        let hasLocationChanged: Bool
        if let previousLocation = currentUserLocation {
            let distance = calculateDistance(from: previousLocation, to: newLocation)
            hasLocationChanged = distance > 3.0 // 3미터 이상 변경시에만
            print("📍 위치 거리 계산: \(String(format: "%.2f", distance))m (임계값: 3.0m)")
        } else {
            hasLocationChanged = true // 첫 번째 위치 업데이트
            print("📍 첫 번째 위치 업데이트")
        }
        
        currentUserLocation = newLocation
        
        // 위치가 변경되었을 때만 마커 체크 및 카메라 업데이트
        if hasLocationChanged {
            print("✅ 위치 변경 감지됨: \(newLocation.lat), \(newLocation.lng)")
            print("📍 현재 가이드 리스트 개수: \(guideList.count)")
            print("📍 현재 마커 개수: \(markerCoordinates.count)")
            checkAndRemovePassedMarkers()
            updateCameraToUserLocation()
        } else {
            print("⏸️ 사용자가 움직이지 않음 - 카메라 추적 중단")
        }
    }
    
    // 지나간 마커를 확인하고 제거 (특정 좌표를 지나가면 그 이전의 모든 좌표들 제거)
    private func checkAndRemovePassedMarkers() {
        guard let userLocation = currentUserLocation else { 
            print("❌ 사용자 위치가 없어서 마커 확인 불가")
            return 
        }
        
        print("🎯 === 마커 지나감 확인 시작 ===")
        print("🎯 사용자 위치: \(userLocation.lat), \(userLocation.lng)")
        print("🎯 마커 개수: \(markerCoordinates.count)")
        print("🎯 임계값: \(markerPassThreshold)m")
        
        // 가장 가까운 마커의 인덱스 찾기
        var closestMarkerIndex: Int? = nil
        var minDistance = Double.infinity
        
        for (index, markerCoord) in markerCoordinates.enumerated() {
            let distance = calculateDistance(from: userLocation, to: markerCoord)
            print("🎯 마커[\(index)]: \(markerCoord.lat), \(markerCoord.lng) - 거리: \(String(format: "%.2f", distance))m")
            
            if distance <= markerPassThreshold && distance < minDistance {
                minDistance = distance
                closestMarkerIndex = index
                print("🎯 새로운 가장 가까운 마커 발견! 인덱스: \(index), 거리: \(String(format: "%.2f", distance))m")
            }
        }
        
        // 가장 가까운 마커를 지나갔다면, 그 마커 이전의 모든 마커들 제거
        if let closestIndex = closestMarkerIndex {
            let removedCount = closestIndex + 1
            
            print("✅ 🎯 가까운 마커 발견! 인덱스: \(closestIndex), 거리: \(String(format: "%.2f", minDistance))m")
            print("✅ 제거할 마커 개수: \(removedCount)개")
            print("✅ 제거할 마커 인덱스: 0~\(closestIndex)")
            
            // guideList의 좌표를 지날 때 showToilet과 showConvenienceStore 상태에 따라 토글 함수 호출
            checkAndToggleFacilities(userLocation: userLocation)
            
            // 메인 스레드에서 @Published 프로퍼티들 업데이트
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 마커 좌표와 아이콘에서 제거 (0부터 closestIndex까지)
                self.markerCoordinates.removeFirst(removedCount)
                self.markerIcons.removeFirst(removedCount)
                
                // 가이드 리스트에서도 제거
                if removedCount <= self.guideList.count {
                    self.guideList.removeFirst(removedCount)
                }
                
                // 경로 좌표는 라이딩 중에 제거하지 않음 (전체 경로 유지)
                // if removedCount <= self.pathCoordinates.count {
                //     self.pathCoordinates.removeFirst(removedCount)
                // }
                
                // 디버깅용 로그
                print("✅ 지나간 마커 \(removedCount)개 제거됨 (인덱스 0~\(closestIndex))")
                print("✅ 남은 가이드 리스트: \(self.guideList.count)개")
                print("✅ 남은 마커: \(self.markerCoordinates.count)개")
                print("✅ 남은 경로 좌표: \(self.pathCoordinates.count)개")
            }
            
            // 실제 지도에서 마커 업데이트
            updateMarkersOnMap()
            
        } else {
            print("⏸️ 가까운 마커 없음 (임계값: \(markerPassThreshold)m)")
            print("⏸️ 모든 마커가 \(markerPassThreshold)m보다 멀리 있음")
        }
        
        print("🎯 === 마커 지나감 확인 완료 ===")
    }
    
    // guideList의 좌표를 지날 때 showToilet과 showConvenienceStore 상태에 따라 마커 업데이트 함수 호출
    private func checkAndToggleFacilities(userLocation: NMGLatLng) {
        print("🔍 === guideList 좌표 지나감 확인 시작 ===")
        print("🔍 사용자 위치: \(userLocation.lat), \(userLocation.lng)")
        print("🔍 guideList 개수: \(guideList.count)")
        print("🔍 임계값: \(markerPassThreshold)m")
        
        // guideList의 각 좌표와 사용자 위치 간의 거리 확인
        for (index, guide) in guideList.enumerated() {
            if let lat = Double(guide.lat), let lon = Double(guide.lon) {
                let guideLocation = NMGLatLng(lat: lat, lng: lon)
                let distance = calculateDistance(from: userLocation, to: guideLocation)
                
                print("🔍 guideList[\(index)]: \(guide.lat), \(guide.lon) - 거리: \(String(format: "%.2f", distance))m")
                
                // guideList의 좌표를 지났는지 확인 (임계값: 100m)
                if distance <= markerPassThreshold {
                    print("✅ 🏃‍♂️ guideList 좌표 지남 감지!")
                    print("✅ 좌표: \(guide.lat), \(guide.lon)")
                    print("✅ 거리: \(String(format: "%.2f", distance))m (임계값: \(markerPassThreshold)m)")
                    print("✅ 가이드 타입: \(guide.guideType?.rawValue ?? "unknown")")
                    print("✅ 가이드 설명: \(guide.instructions)")
                    
                    // 메인 스레드에서 편의시설 마커 업데이트
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        // showToilet이 true이면 updateToiletMarkers 함수 호출 (토글 없이)
                        if self.showToilet {
                            print("🚽 showToilet이 true이므로 updateToiletMarkers 함수 호출")
                            let locationString = "\(guide.lat),\(guide.lon)"
                            self.updateToiletMarkers(location: locationString)
                        }
                        
                        // showConvenienceStore가 true이면 updateConvenienceStoreMarkers 함수 호출 (토글 없이)
                        if self.showConvenienceStore {
                            print("🏪 showConvenienceStore가 true이므로 updateConvenienceStoreMarkers 함수 호출")
                            let locationString = "\(guide.lat),\(guide.lon)"
                            self.updateConvenienceStoreMarkers(location: locationString)
                        }
                    }
                    
                    // 한 번만 처리하고 break (가장 가까운 좌표만 처리)
                    print("🔍 가장 가까운 좌표 처리 완료 - 루프 종료")
                    break
                } else {
                    print("⏸️ guideList[\(index)] 아직 멀음 - 거리: \(String(format: "%.2f", distance))m")
                }
            } else {
                print("❌ guideList[\(index)] 좌표 변환 실패: lat=\(guide.lat), lon=\(guide.lon)")
            }
        }
        
        print("🔍 === guideList 좌표 지나감 확인 완료 ===")
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
              let mapView = mapView else { 
            print("❌ 카메라 업데이트 실패: userLocation 또는 mapView가 nil")
            return 
        }
        
        // 메인 스레드에서 카메라 업데이트 실행
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let cameraUpdate = NMFCameraUpdate(scrollTo: userLocation)
            cameraUpdate.pivot = CGPoint(x: 0.5, y: 0.3) // x: 0.5(가로 중앙), y: 0.3(세로 위쪽)
            cameraUpdate.animation = .easeIn
            mapView.moveCamera(cameraUpdate)
            
            print("📷 카메라가 사용자 위치로 업데이트됨: \(userLocation.lat), \(userLocation.lng)")
            print("📷 사용자가 움직였으므로 카메라가 따라감")
        }
    }
    
    // 지도에서 마커 업데이트
    private func updateMarkersOnMap() {
        guard let markerManager = markerManager else { 
            print("❌ 마커 업데이트 실패: markerManager가 nil")
            return 
        }
        
        // 메인 스레드에서 마커 업데이트 실행
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 기존 마커들을 모두 제거하고 새로운 마커들로 업데이트
            markerManager.clearMarkers()
            markerManager.addMarkers(coordinates: self.markerCoordinates, icons: self.markerIcons)
            
            print("🗺️ 지도에서 마커 업데이트 완료: \(self.markerCoordinates.count)개")
        }
    }

}
