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
    func updateUserLocationAndCheckMarkers(_ newLocation: NMGLatLng) async {
        print("🔄 === 위치 업데이트 시작 ===")
        print("🔄 flag 상태: \(flag)")
        print("🔄 guideList 개수: \(guideList.count)")
        print("🔄 markerCoordinates 개수: \(markerCoordinates.count)")
        print("🔄 사용자 위치: \(newLocation.lat), \(newLocation.lng)")
        
        // 라이딩 중일 때만 마커 추적 및 카메라 업데이트
        guard flag else { 
            print("🚫 라이딩 중이 아니므로 위치 추적 중단")
            return 
        }
        
        // 비정상 종료 시 가이드 데이터가 아직 로드되지 않은 경우 대기
        if guideList.isEmpty {
            print("⚠️ 가이드 데이터가 비어있음 - 위치 업데이트 건너뜀")
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
        
        // @MainActor로 메인 스레드에서 currentUserLocation 업데이트
        await MainActor.run {
            currentUserLocation = newLocation
        }
        
        // 위치가 변경되었을 때만 마커 체크 및 카메라 업데이트
        if hasLocationChanged {
            print("✅ 위치 변경 감지됨: \(newLocation.lat), \(newLocation.lng)")
            print("📍 현재 가이드 리스트 개수: \(guideList.count)")
            print("📍 현재 마커 개수: \(markerCoordinates.count)")
            
            // 마커 체크와 카메라 업데이트를 순차적으로 실행하여 간섭 방지
            await checkAndRemovePassedMarkers()
            await updateCameraToUserLocation()
        } else {
            print("⏸️ 사용자가 움직이지 않음 - 카메라 추적 중단")
        }
    }
    
    // 지나간 마커를 확인하고 제거 (특정 좌표를 지나가면 그 이전의 모든 좌표들 제거)
    private func checkAndRemovePassedMarkers() async {
        guard let userLocation = currentUserLocation else { 
            print("❌ 사용자 위치가 없어서 마커 확인 불가")
            return 
        }
        
        print("🎯 === 마커 지나감 확인 시작 ===")
        print("🎯 사용자 위치: \(userLocation.lat), \(userLocation.lng)")
        print("🎯 마커 개수: \(markerCoordinates.count)")
        print("🎯 임계값: \(markerPassThreshold)m")
        
        // 임계값 안에 마커가 있는지만 본다.
        //
        // 이전에는 "가장 가까운" 마커를 찾아 0...그 인덱스를 한꺼번에 지웠다.
        // 그래서 30m 안에 마커가 둘 이상 들어오거나 GPS가 튀면 그 사이 안내가
        // 화면에 한 번도 뜨지 않고 사라졌다. 실제 fixture에 20.7m·21.2m 간격 구간이 있다.
        //
        // 한 번의 위치 갱신에 한 칸만 소비한다. 여러 칸 밀렸으면 다음 갱신들로 따라잡는다
        // (위치 콜백이 3m 이동마다 오므로 두 칸이면 약 6m 주행).
        var nearestDistance = Double.infinity
        var hasMarkerWithinThreshold = false

        for (index, markerCoord) in markerCoordinates.enumerated() {
            let distance = calculateDistance(from: userLocation, to: markerCoord)
            print("🎯 마커[\(index)]: \(markerCoord.lat), \(markerCoord.lng) - 거리: \(String(format: "%.2f", distance))m")

            if distance <= markerPassThreshold {
                hasMarkerWithinThreshold = true
                nearestDistance = min(nearestDistance, distance)
            }
        }

        if hasMarkerWithinThreshold {
            print("✅ 🎯 임계값 안 마커 있음 (최근접 \(String(format: "%.2f", nearestDistance))m) - 맨 앞 한 칸만 소비")

            // guideList의 좌표를 지날 때 showToilet과 showConvenienceStore 상태에 따라 토글 함수 호출
            await checkAndToggleFacilities(userLocation: userLocation)

            // @MainActor를 사용하여 동기적으로 처리
            await removePassedMarkers(removedCount: 1, closestIndex: 0)

        } else {
            print("⏸️ 가까운 마커 없음 (임계값: \(markerPassThreshold)m)")
            print("⏸️ 모든 마커가 \(markerPassThreshold)m보다 멀리 있음")
        }
        
        print("🎯 === 마커 지나감 확인 완료 ===")
    }
    
    // 지나간 마커들을 제거하는 메서드 (@MainActor로 동기 처리)
    @MainActor
    private func removePassedMarkers(removedCount: Int, closestIndex: Int) {
        // 마커 좌표와 아이콘에서 제거 (0부터 closestIndex까지)
        markerCoordinates.removeFirst(removedCount)
        markerIcons.removeFirst(removedCount)
        
        // 가이드 리스트에서도 제거
        if removedCount <= guideList.count {
            guideList.removeFirst(removedCount)
        }
        
        // 경로 좌표는 라이딩 중에 제거하지 않음 (전체 경로 유지)
        // 라이딩 중에는 경로선이 계속 표시되어야 함
        // if removedCount <= pathCoordinates.count {
        //     pathCoordinates.removeFirst(removedCount)
        // }
        
        // 디버깅용 로그
        print("✅ 지나간 마커 \(removedCount)개 제거됨 (인덱스 0~\(closestIndex))")
        print("✅ 남은 가이드 리스트: \(guideList.count)개")
        print("✅ 남은 마커: \(markerCoordinates.count)개")
        print("✅ 남은 경로 좌표: \(pathCoordinates.count)개")
        
        // 실제 지도에서 마커 업데이트 (메인 스레드에서 즉시 실행)
        updateMarkersOnMap()
        print("🗺️ 마커 제거 후 지도 업데이트 완료")
    }
    
    // guideList의 좌표를 지날 때 showToilet과 showConvenienceStore 상태에 따라 마커 업데이트 함수 호출
    private func checkAndToggleFacilities(userLocation: NMGLatLng) async {
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
                    
                    // @MainActor를 사용하여 동기적으로 처리
                    await updateFacilityMarkers(guide: guide)
                    
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
    
    // 편의시설 마커 업데이트 메서드 (@MainActor로 동기 처리)
    @MainActor
    private func updateFacilityMarkers(guide: GuideModel) {
        // showToilet이 true이면 updateToiletMarkers 함수 호출 (토글 없이)
        if showToilet {
            print("🚽 showToilet이 true이므로 updateToiletMarkers 함수 호출")
            let locationString = "\(guide.lat),\(guide.lon)"
            updateToiletMarkers(location: locationString)
        }
        
        // showConvenienceStore가 true이면 updateConvenienceStoreMarkers 함수 호출 (토글 없이)
        if showConvenienceStore {
            print("🏪 showConvenienceStore가 true이므로 updateConvenienceStoreMarkers 함수 호출")
            let locationString = "\(guide.lat),\(guide.lon)"
            updateConvenienceStoreMarkers(location: locationString)
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
    
    // 사용자 위치로 카메라 업데이트 (@MainActor로 동기 처리)
    @MainActor
    private func updateCameraToUserLocation() {
        guard let userLocation = currentUserLocation,
              let mapView = mapView,
              let userLocationManager = userLocationManager else { 
            print("❌ 카메라 업데이트 실패: userLocation, mapView 또는 userLocationManager가 nil")
            return 
        }
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: userLocation)
        // 바텀시트 높이에 따른 동적 피봇 조정 (하드코딩 제거)
        cameraUpdate.pivot = CGPoint(x: 0.5, y: userLocationManager.cameraPivotY)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        print("📷 카메라가 사용자 위치로 업데이트됨: \(userLocation.lat), \(userLocation.lng)")
        print("📷 사용자가 움직였으므로 카메라가 따라감 (피봇: \(userLocationManager.cameraPivotY))")
    }
    
    // 지도에서 마커 업데이트 (@MainActor로 동기 처리)
    @MainActor
    private func updateMarkersOnMap() {
        guard let markerManager = markerManager else { 
            print("❌ 마커 업데이트 실패: markerManager가 nil")
            return 
        }
        
        // 기존 마커들을 모두 제거하고 새로운 마커들로 업데이트
        print("🗺️ 마커 업데이트 시작 - 제거할 마커: \(markerManager.getMarkers().count)개, 추가할 마커: \(markerCoordinates.count)개")
        
        // 마커 업데이트를 배치로 처리하여 UI 깜빡임 방지
        markerManager.clearMarkers()
        
        // 새로운 마커 추가 (좌표와 아이콘이 일치하는지 확인)
        if markerCoordinates.count == markerIcons.count {
            markerManager.addMarkers(coordinates: markerCoordinates, icons: markerIcons)
            print("🗺️ 지도에서 마커 업데이트 완료: \(markerCoordinates.count)개")
        } else {
            print("❌ 마커 좌표와 아이콘 개수가 일치하지 않음: 좌표 \(markerCoordinates.count)개, 아이콘 \(markerIcons.count)개")
        }
        
        // 편의시설 마커도 함께 업데이트
        updateFacilityMarkersOnMap()
    }
    
    // 편의시설 마커 업데이트
    @MainActor
    private func updateFacilityMarkersOnMap() {
        guard let markerManager = markerManager else { return }
        
        // 화장실 마커 업데이트
        if !toiletMarkerCoordinates.isEmpty && toiletMarkerCoordinates.count == toiletMarkerIcons.count {
            markerManager.addToiletMarkers(coordinates: toiletMarkerCoordinates, icons: toiletMarkerIcons)
        }
        
        // 편의점 마커 업데이트
        if !csMarkerCoordinates.isEmpty && csMarkerCoordinates.count == csMarkerIcons.count {
            markerManager.addCSMarkers(coordinates: csMarkerCoordinates, icons: csMarkerIcons)
        }
    }

}
