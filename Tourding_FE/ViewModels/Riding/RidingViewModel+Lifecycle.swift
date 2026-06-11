//
//  RidingViewModel+Lifecycle.swift
//  Tourding_FE
//
//  RidingView appear / riding start·end / foreground / location tracking
//

import CoreLocation
import Foundation
import NMapsMap

extension RidingViewModel {

    // MARK: - onAppear

    @MainActor
    func configureLocationManager(_ locationManager: LocationManager) {
        userLocationManager = locationManager
        if let mapView {
            locationManager.setMapView(mapView)
        }
    }

    @MainActor
    func handleOnAppear(
        locationManager: LocationManager,
        isNotNormal: Bool?,
        isStart: Bool,
        onStartRiding: @escaping () -> Void
    ) {
        handleSpotAddReturnIfNeeded(isNotNormal: isNotNormal, isStart: isStart)

        if let isNotNormal {
            flag = isNotNormal
            print("🔄 비정상 종료 감지 - 라이딩 모드로 복구")
            onStartRiding()
        } else if isStart {
            onStartRiding()
        }

        let isSpotAddReturn = isNotNormal == nil && !isStart
        setupRidingNavigationOnAppear(locationManager: locationManager, isSpotAddReturn: isSpotAddReturn)

        Task { [weak self] in
            await self?.loadEditModeRouteData(cameraOnlyWhenNotRiding: true)
        }
    }

    @MainActor
    private func handleSpotAddReturnIfNeeded(isNotNormal: Bool?, isStart: Bool) {
        guard isNotNormal == nil, !isStart else { return }

        print("🔄 SpotAddView로부터 돌아옴 - flag 상태 확인")
        print("  - 현재 flag: \(flag)")
        print("  - isNotNormal: \(isNotNormal != nil)")
        print("  - isStart: \(isStart)")

        flag = false
        print("✅ flag를 false로 초기화")
    }

    @MainActor
    private func setupRidingNavigationOnAppear(locationManager: LocationManager, isSpotAddReturn: Bool) {
        guard flag, !isSpotAddReturn else { return }

        print("🎯 onAppear - 라이딩 중, startRidingProcess 로직 실행")
        startRidingNavigationMode(locationManager: locationManager, logPrefix: "onAppear")
        print("📍 onAppear - 콜백 설정은 startRidingAPIProcess에서 처리됨")
    }

    // MARK: - Edit mode route load (P1)

    func loadEditModeRouteData(cameraOnlyWhenNotRiding: Bool) async {
        do {
            try Task.checkCancellation()
            await getRoutesTotalAPI()

            try Task.checkCancellation()
            await getRouteLocationAPI()

            try Task.checkCancellation()
            await getRoutePathAPI()

            try Task.checkCancellation()
            await MainActor.run {
                setEditModeCameraToRouteStart(force: !cameraOnlyWhenNotRiding)
            }
        } catch is CancellationError {
            print("🚫 RidingView 초기화 Task 취소됨")
        } catch {
            print("❌ RidingView 초기화 에러: \(error)")
        }
    }

    func refreshEditModeRouteData() async {
        do {
            try Task.checkCancellation()
            await getRoutesTotalAPI()

            try Task.checkCancellation()
            await getRouteLocationAPI()

            try Task.checkCancellation()
            await getRoutePathAPI()

            try Task.checkCancellation()
            await MainActor.run {
                setEditModeCameraToRouteStart(force: true)
            }
        } catch is CancellationError {
            print("🚫 경로 데이터 새로고침 Task 취소됨")
        } catch {
            print("❌ 경로 데이터 새로고침 에러: \(error)")
        }
    }

    @MainActor
    private func setEditModeCameraToRouteStart(force: Bool) {
        guard let firstLocation = routeLocation.first,
              let lat = Double(firstLocation.lat),
              let lon = Double(firstLocation.lon),
              let mapView else {
            print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
            return
        }

        guard force || !flag else { return }

        let coordinate = NMGLatLng(lat: lat, lng: lon)
        locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)

        if force {
            print("✅ 새로고침 후 초기 카메라 위치 설정 완료: \(lat), \(lon)")
        } else {
            print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
        }
    }

    // MARK: - Foreground

    @MainActor
    func handleForegroundRefresh() {
        guard !flag else {
            print("🚫 라이딩 중이므로 데이터 새로고침 건너뜀")
            return
        }

        if routeLocation.isEmpty || pathCoordinates.isEmpty {
            print("🔄 경로 데이터가 비어있음 - API 재호출 시작")
            Task { [weak self] in
                await self?.refreshEditModeRouteData()
            }
        } else {
            refreshMapDisplay()
        }
    }

    // MARK: - routeLocation change (edit mode)

    @MainActor
    func handleRouteLocationChangedInEditMode() {
        guard !flag else { return }

        print("🔄 routeLocation 변경 감지 - getRoutesTotalAPI 호출")
        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRoutesTotalAPI()
                print("✅ getRoutesTotalAPI 호출 완료")
            } catch is CancellationError {
                print("🚫 getRoutesTotalAPI Task 취소됨")
            } catch {
                print("❌ getRoutesTotalAPI 에러: \(error)")
            }
        }
    }

    // MARK: - Riding start

    func startRidingWithLoading(
        isNotNormal: Bool?,
        locationManager: LocationManager,
        onMarkAbnormalExit: @escaping () -> Void
    ) {
        onMarkAbnormalExit()
        isStartingRiding = true

        Task { @MainActor in
            await startRidingAPIProcess(isNotNormal: isNotNormal, locationManager: locationManager)
            print("✅ 라이딩 시작 프로세스 완료 - 로딩 종료")
            isStartingRiding = false
        }
    }

    @MainActor
    func startRidingAPIProcess(isNotNormal: Bool?, locationManager: LocationManager) async {
        flag = true

        setupRidingLocationCallback(locationManager: locationManager)
        print("📍 startRidingProcess - 통합된 위치 추적 콜백 설정 완료")

        startRidingNavigationMode(locationManager: locationManager, logPrefix: "startRidingProcess")

        Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.getRouteGuideAPI(isNotNormal: isNotNormal)
                print("✅ 라이딩 가이드 API 호출 완료")
            } catch is CancellationError {
                print("🚫 라이딩 가이드 API Task 취소됨")
            } catch {
                print("❌ 라이딩 가이드 API 에러: \(error)")
            }
        }
    }

    // MARK: - Riding end

    @MainActor
    func endRiding(isStart: Bool, locationManager: LocationManager) async {
        locationManager.stopLocationUpdates()
        locationManager.stopNavigationMode()
        locationManager.cancelAutoTrackingTimer()

        if let firstLocation = routeLocation.first,
           let lat = Double(firstLocation.lat),
           let lon = Double(firstLocation.lon),
           let mapView {
            let coordinate = NMGLatLng(lat: lat, lng: lon)
            self.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
            print("초기 카메라 위치를 경로 첫 번째 좌표로 설정: \(lat), \(lon)")
        } else {
            print("❌ 초기 카메라 위치 설정 실패: mapView 또는 경로 데이터가 없습니다")
        }

        do {
            try Task.checkCancellation()
            await getRoutesTotalAPI()

            try Task.checkCancellation()
            await getRouteLocationAPI()

            try Task.checkCancellation()
            await getRoutePathAPI()

            toiletMarkerCoordinates.removeAll()
            toiletMarkerIcons.removeAll()
            csMarkerCoordinates.removeAll()
            csMarkerIcons.removeAll()
            showConvenienceStore = false
            showToilet = false

            restoreOriginalData(isStart: isStart)
            flag = false
        } catch is CancellationError {
            print("🚫 라이딩 종료 Task 취소됨")
        } catch {
            print("❌ 라이딩 종료 에러: \(error)")
        }
    }

    // MARK: - Location tracking

    @MainActor
    func activateRidingLocationTracking(locationManager: LocationManager) {
        print("🔄 flag가 true로 변경됨 - 위치 추적 완전 재시작")

        setupRidingLocationCallback(locationManager: locationManager)
        print("📍 onChange - 통합된 위치 추적 콜백 재설정 완료")

        locationManager.startLocationUpdates()
        print("🌍 onChange - 위치 업데이트 재시작")

        if let mapView {
            locationManager.startNavigationMode(on: mapView)
            print("🧭 onChange - 네비게이션 모드 재시작")
        } else {
            print("❌ onChange - mapView가 nil이어서 네비게이션 모드 재시작 실패")
        }
    }

    @MainActor
    func setupRidingLocationCallback(locationManager: LocationManager) {
        locationManager.onLocationUpdate = nil
        locationManager.onLocationUpdateNMGLatLng = { [weak self] newLocation in
            print("📍 위치 콜백 호출됨: \(newLocation.lat), \(newLocation.lng)")

            Task { @MainActor in
                guard let self else { return }

                if let mapViewController = self.mapViewController {
                    let clLocation = CLLocation(latitude: newLocation.lat, longitude: newLocation.lng)
                    mapViewController.updateUserLocation(clLocation)
                }

                await self.updateUserLocationAndCheckMarkers(newLocation)
            }
        }
    }

    @MainActor
    private func startRidingNavigationMode(locationManager: LocationManager, logPrefix: String) {
        if let coordinate = locationManager.getCurrentLocationAsNMGLatLng(),
           let mapView {
            self.locationManager?.setInitialCameraPosition(to: coordinate, on: mapView)
            print("🎯 \(logPrefix) - 카메라를 사용자 위치로 이동: \(coordinate.lat), \(coordinate.lng)")
            print("🧭 \(logPrefix) - 나침반 사용 가능 여부: \(CLLocationManager.headingAvailable())")
            locationManager.startNavigationMode(on: mapView)
        } else {
            print("❌ \(logPrefix) - 사용자 위치 또는 mapView를 가져올 수 없어 카메라 이동 실패")

            if let mapView {
                print("🧭 \(logPrefix) - 위치 없이 네비게이션 모드 시작 (위치 업데이트 대기)")
                locationManager.startNavigationMode(on: mapView)
            }
        }
    }
}
