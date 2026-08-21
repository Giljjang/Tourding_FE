//
//  FacilityMarkerTests.swift
//  Tourding_FETests
//
//  화장실·편의점 마커 갱신이 추적 가능한 Task를 통해 이뤄지는지.
//
//  기존 구조는 `Task { }`를 핸들 없이 띄워서
//  (a) 테스트가 완료를 기다릴 수 없고
//  (b) 라이딩 종료 후에도 취소되지 않아 지운 마커를 되살리며
//  (c) 중복 호출이 직렬화되지 않았다.
//

import Testing
@testable import Tourding_FE

@MainActor
struct FacilityMarkerTests {

    private func facility(_ name: String, lat: String, lon: String) -> FacilityInfoModel {
        FacilityInfoModel(name: name, lon: lon, lat: lat)
    }

    // MARK: - 순수 상태 갱신

    /// 좌표는 compactMap, 아이콘은 map으로 만들면 개수가 어긋난다.
    /// 아이콘을 좌표에서 파생시켜 구조적으로 같은 개수가 되어야 한다.
    @Test func applyToiletMarkersKeepsCoordinateAndIconCountsEqual() {
        let viewModel = makeTestRidingViewModel()
        viewModel.toiletList = [
            facility("화장실1", lat: "37.1", lon: "127.1"),
            facility("좌표깨짐", lat: "", lon: ""),
            facility("화장실2", lat: "37.2", lon: "127.2")
        ]

        viewModel.applyToiletMarkers()

        #expect(viewModel.toiletMarkerCoordinates.count == 2)
        #expect(viewModel.toiletMarkerIcons.count == viewModel.toiletMarkerCoordinates.count)
    }

    @Test func applyConvenienceStoreMarkersKeepsCoordinateAndIconCountsEqual() {
        let viewModel = makeTestRidingViewModel()
        viewModel.csList = [
            facility("편의점1", lat: "37.1", lon: "127.1"),
            facility("좌표깨짐", lat: "abc", lon: "def")
        ]

        viewModel.applyConvenienceStoreMarkers()

        #expect(viewModel.csMarkerCoordinates.count == 1)
        #expect(viewModel.csMarkerIcons.count == viewModel.csMarkerCoordinates.count)
    }

    // MARK: - Task 노출

    /// Task.sleep 없이 완료를 기다릴 수 있어야 한다
    @Test func updateToiletMarkersCompletesThroughExposedTask() async throws {
        let kakao = FakeKakaoRepository()
        kakao.toilets = [
            facility("화장실1", lat: "37.1", lon: "127.1"),
            facility("화장실2", lat: "37.2", lon: "127.2")
        ]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.updateToiletMarkers(location: "37.0,127.0")
        let task = try #require(viewModel.toiletMarkerTask)
        await task.value

        #expect(viewModel.toiletMarkerCoordinates.count == 2)
    }

    @Test func updateConvenienceStoreMarkersCompletesThroughExposedTask() async throws {
        let kakao = FakeKakaoRepository()
        kakao.stores = [facility("편의점1", lat: "37.1", lon: "127.1")]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.updateConvenienceStoreMarkers(location: "37.0,127.0")
        let task = try #require(viewModel.convenienceStoreMarkerTask)
        await task.value

        #expect(viewModel.csMarkerCoordinates.count == 1)
    }

    // MARK: - 취소

    /// 라이딩 종료로 마커를 지운 뒤 뒤늦게 끝난 Task가 되살리면 안 된다
    @Test func cancelledFacilityTaskDoesNotRestoreClearedMarkers() async throws {
        let kakao = FakeKakaoRepository()
        kakao.toilets = [facility("화장실1", lat: "37.1", lon: "127.1")]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.updateToiletMarkers(location: "37.0,127.0")
        let task = try #require(viewModel.toiletMarkerTask)

        viewModel.cancelFacilityMarkerTasks()
        viewModel.toiletMarkerCoordinates.removeAll()
        viewModel.toiletMarkerIcons.removeAll()
        await task.value

        #expect(viewModel.toiletMarkerCoordinates.isEmpty)
        #expect(viewModel.toiletMarkerIcons.isEmpty)
    }

    /// 토글을 껐는데 직전 요청이 뒤늦게 끝나면 마커가 되살아난다
    @Test func togglingToiletOffDiscardsPendingRequest() async throws {
        let kakao = FakeKakaoRepository()
        kakao.toilets = [facility("화장실1", lat: "37.1", lon: "127.1")]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.toggleToilet(location: "37.0,127.0")          // ON — 요청 시작
        let task = try #require(viewModel.toiletMarkerTask)
        viewModel.toggleToilet(location: "37.0,127.0")          // OFF — 마커 제거
        await task.value

        #expect(viewModel.showToilet == false)
        #expect(viewModel.toiletMarkerCoordinates.isEmpty)
    }

    /// 라이딩 종료가 진행 중이던 편의시설 요청을 정리하는지.
    /// (되살아남 자체는 위 cancelledFacilityTask... 테스트가 결정적으로 증명하고,
    ///  여기서는 endRiding이 그 정리를 실제로 호출하는지를 본다)
    @Test func endRidingClearsFacilityMarkerTasks() async {
        let kakao = FakeKakaoRepository()
        kakao.toilets = [facility("화장실1", lat: "37.1", lon: "127.1")]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.updateToiletMarkers(location: "37.0,127.0")
        await viewModel.endRiding(isStart: false, locationManager: LocationManager())

        #expect(viewModel.toiletMarkerTask == nil)
        #expect(viewModel.convenienceStoreMarkerTask == nil)
    }

    /// 새 요청은 이전 요청을 취소해 오래된 응답이 최신을 덮지 않게 한다
    @Test func newFacilityRequestCancelsPreviousOne() async throws {
        let kakao = FakeKakaoRepository()
        kakao.toilets = [facility("화장실1", lat: "37.1", lon: "127.1")]
        let viewModel = makeTestRidingViewModel(kakaoRepository: kakao)

        viewModel.updateToiletMarkers(location: "37.0,127.0")
        let first = try #require(viewModel.toiletMarkerTask)
        viewModel.updateToiletMarkers(location: "37.5,127.5")
        let second = try #require(viewModel.toiletMarkerTask)

        #expect(first.isCancelled)
        await second.value
        #expect(viewModel.toiletMarkerCoordinates.count == 1)
    }
}
