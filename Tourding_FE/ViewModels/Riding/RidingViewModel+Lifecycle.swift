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
        // 지도용·위치용 참조가 같은 인스턴스를 가리켜야 한다.
        // 갈라지면 LocationManager가 두 벌 살아 GPS·나침반 스트림이 두 개 돈다.
        userLocationManager = locationManager
        self.locationManager = locationManager
        if let mapView {
            locationManager.setMapView(mapView)
        }
    }

    @MainActor
    func handleInitialEntry(
        locationManager: LocationManager,
        isNotNormal: Bool?,
        isStart: Bool,
        routeSource: RidingRouteSource,
        onStartRiding: @escaping () -> Void
    ) {
        // 이후 재정렬 POST·경로선 재조회·포그라운드 새로고침이 모두 이 값을 참조한다
        self.routeSource = routeSource

        if let isNotNormal {
            flag = isNotNormal
            print("🔄 비정상 종료 감지 - 라이딩 모드로 복구")
            onStartRiding()
        } else if isStart {
            onStartRiding()
        }

        setupRidingNavigationOnAppear(locationManager: locationManager)

        scheduleRidingProfileLoad()

        Task { [weak self] in
            await self?.loadEditModeRouteData(
                cameraOnlyWhenNotRiding: true,
                routeSource: routeSource
            )
        }
    }

    @MainActor
    func handleReturnFromChild(locationManager: LocationManager, routeSource: RidingRouteSource) {
        guard !flag else { return }

        print("🔄 자식 화면에서 복귀 - 편집 모드 유지")
        flag = false
        self.routeSource = routeSource

        // 자식 화면 중 하나가 라이딩 스타일 설정이다.
        //
        // **스타일이 바뀌었으면 경로를 다시 계산해야 한다.**
        // GET /routes는 서버에 저장된 경로를 그대로 읽을 뿐이라 스타일을 바꿔도 그대로다
        // (실측: 저장 전후의 거리·좌표 개수가 글자 하나까지 같았다).
        // 코스 편집에서 고른 스타일은 서버에 저장조차 하지 않으므로 POST가 유일한 반영 경로다.
        //
        // 조회와 재계산이 순서대로 일어나야 하므로 하나의 Task로 묶는다 —
        // 따로 띄우면 스타일을 읽기 전에 새로고침이 끝난다.
        pendingProfileLoad?.cancel()
        pendingProfileLoad = Task { [weak self] in
            guard let self else { return }

            let previous = routeOption
            await loadRidingProfile()

            #if DEBUG
            if routeOption != previous {
                print("♻️ [Style] 변경 감지: \(previous?.logDescription ?? "없음") → \(routeOption?.logDescription ?? "없음")")
            } else {
                print("♻️ [Style] 변경 없음 — 재계산 생략 (\(routeOption?.logDescription ?? "없음"))")
            }
            #endif

            if routeOption != previous, await recalculateRouteWithCurrentStyle() {
                return   // 재계산 응답을 이미 반영했다 — GET을 또 부를 이유가 없다
            }

            await refreshEditModeRouteData(routeSource: routeSource)
        }
    }

    @MainActor
    private func setupRidingNavigationOnAppear(locationManager: LocationManager) {
        guard flag else { return }

        print("🎯 onAppear - 라이딩 중, startRidingProcess 로직 실행")
        startRidingNavigationMode(locationManager: locationManager, logPrefix: "onAppear")
        print("📍 onAppear - 콜백 설정은 startRidingAPIProcess에서 처리됨")
    }

    // MARK: - 경유지 삭제

    /// 삭제 POST와 이어지는 재조회가 **같은 경로**를 가리키도록 한 곳에서 오케스트레이션한다.
    @MainActor
    func deleteWaypointAndRefresh(_ item: LocationNameModel) async {
        let source = isUsedRoute
        await postRouteDeleteAPI(originalData: routeLocation, selectedData: item)
        await getRouteLocationAPI(isUsedOverride: source)
        await getRoutePathAPI(isUsed: source)
    }

    // MARK: - Edit mode route load (P1)

    func loadEditModeRouteData(
        cameraOnlyWhenNotRiding: Bool,
        routeSource: RidingRouteSource
    ) async {
        // #region agent log
        await MainActor.run {
            DebugSessionLogger.log(
                location: "RidingViewModel+Lifecycle.swift:loadEditModeRouteData",
                message: "riding edit load started",
                hypothesisId: "H1_H4",
                data: [
                    "flag": String(flag),
                    "routeSource": String(describing: routeSource),
                    "isUsed": String(routeSource.isUsed),
                    "existingFirst": routeLocation.first?.name ?? "nil",
                    "existingLast": routeLocation.last?.name ?? "nil",
                    "existingCount": String(routeLocation.count)
                ]
            )
        }
        // #endregion
        do {
            try Task.checkCancellation()
            await loadRouteBundleAPI(isUsed: routeSource.isUsed)

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

    func refreshEditModeRouteData(routeSource: RidingRouteSource = .draft) async {
        do {
            try Task.checkCancellation()
            await loadRouteBundleAPI(isUsed: routeSource.isUsed)

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
                guard let self else { return }
                await self.refreshEditModeRouteData(routeSource: self.routeSource)
            }
        } else {
            refreshMapDisplay()
        }
    }

    // MARK: - routeLocation change (edit mode)

    /// 경유지를 드래그하는 동안 `routeLocation`은 매 프레임 재할당된다.
    /// 그때마다 총계를 조회하면 요청이 폭주하므로 디바운스해 마지막 한 번만 나간다.
    @MainActor
    func handleRouteLocationChangedInEditMode() {
        guard !flag else { return }

        print("🔄 routeLocation 변경 감지 - 총계 갱신 예약")
        routeTotalRefreshTask?.cancel()
        routeTotalRefreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else {
                print("🚫 총계 갱신 취소됨")
                return
            }

            await self?.getRoutesTotalAPI(showsLoading: false)
            print("✅ getRoutesTotalAPI 호출 완료")
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

        // Task를 프로퍼티로 붙잡아야 endRiding에서 취소할 수 있다.
        // 놓치면 라이딩을 끝낸 뒤 뒤늦게 끝난 가이드가 편집 모드 화면을 덮는다.
        ridingStartTask?.cancel()
        ridingStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                // 취소로 중간에 빠져나가도 오버레이는 반드시 내려야 한다 (화면 잠김 방지)
                self.isStartingRiding = false
                print("✅ 라이딩 시작 프로세스 종료 - 로딩 해제")
            }

            await self.startRidingAPIProcess(isNotNormal: isNotNormal, locationManager: locationManager)
        }
    }

    @MainActor
    func startRidingAPIProcess(isNotNormal: Bool?, locationManager: LocationManager) async {
        flag = true

        setupRidingLocationCallback(locationManager: locationManager)
        print("📍 startRidingProcess - 통합된 위치 추적 콜백 설정 완료")

        startRidingNavigationMode(locationManager: locationManager, logPrefix: "startRidingProcess")

        // 자식 Task로 띄우면 여기서 즉시 반환해 "시작 완료"로 표시된다.
        // 가이드가 실제로 실릴 때까지 기다려야 로딩 표시와 화면이 맞는다.
        do {
            try Task.checkCancellation()
            await getRouteGuideAPI(isNotNormal: isNotNormal)
            print("✅ 라이딩 가이드 API 호출 완료")
        } catch is CancellationError {
            print("🚫 라이딩 가이드 API Task 취소됨")
        } catch {
            print("❌ 라이딩 가이드 API 에러: \(error)")
        }
    }

    // MARK: - Riding end

    @MainActor
    func endRiding(isStart: Bool, locationManager: LocationManager) async {
        // 진행 중인 편의시설 요청을 먼저 끊는다.
        // 아래 API들을 await하는 동안 뒤늦게 끝나면 지운 마커가 되살아난다.
        cancelFacilityMarkerTasks()

        // 같은 이유로 라이딩 시작(가이드 로드)도 끊는다.
        //
        // 주의: 이 취소가 시작 Task보다 먼저 도달한다고 가정하면 안 된다.
        // 실측(flag 전이 [false, true, false])상 시작 Task가 먼저 실행돼 flag=true까지 찍은 뒤
        // 가이드 요청에서 suspend하고, 그 사이 여기가 돈다. 뒤늦은 가이드를 막는 실제 방어선은
        // getRouteGuideAPI가 응답 도착 후 확인하는 Task.isCancelled다.
        ridingStartTask?.cancel()

        locationManager.stopLocationUpdates()
        locationManager.stopNavigationMode()
        // 시작 전 줌으로 되돌린다. **리셋보다 먼저** — 리셋이 기억해 둔 값을 비운다.
        // 뒤로가기(라이딩 중)와 종료 버튼 모두 이 함수를 거치므로 여기 한 곳이면 된다.
        if let mapView {
            locationManager.restoreZoomBeforeRiding(on: mapView)
        }

        // 다음 라이딩 시작에 줌이 다시 걸리도록. stopNavigationMode에 두면
        // 지도를 밀 때마다 리셋돼 추적 재개마다 줌이 걸린다.
        locationManager.resetRidingStartZoom()

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
            locationManager.startNavigationMode(on: mapView, start: .ridingStart)
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
            locationManager.startNavigationMode(on: mapView, start: .ridingStart)
        } else {
            print("❌ \(logPrefix) - 사용자 위치 또는 mapView를 가져올 수 없어 카메라 이동 실패")

            if let mapView {
                print("🧭 \(logPrefix) - 위치 없이 네비게이션 모드 시작 (위치 업데이트 대기)")
                locationManager.startNavigationMode(on: mapView, start: .ridingStart)
            }
        }
    }
}
