//
//  AppContainerTests.swift
//  Tourding_FETests
//
//  P0-1 — App body에서 DI 그래프를 매 렌더마다 재생성해 ViewModel 상태가 소실되는 문제
//

import Testing
@testable import Tourding_FE

@MainActor
struct AppContainerTests {

    /// 컨테이너는 앱 수명 동안 같은 인스턴스를 내줘야 한다.
    /// 접근할 때마다 새로 만들면 @ObservedObject로 주입된 화면이 빈 인스턴스를 받아
    /// 검색 결과·필터 같은 상태가 사라지고, init 부작용(GPS 시작)도 매번 재실행된다.
    @Test func vendsStableInstancesAcrossAccesses() {
        let container = AppContainer()

        #expect(container.filterBarViewModel === container.filterBarViewModel)
        #expect(container.recentSearchViewModel === container.recentSearchViewModel)
        #expect(container.tabViewModels.homeViewModel === container.tabViewModels.homeViewModel)
        #expect(container.tabViewModels.dsViewModel === container.tabViewModels.dsViewModel)
        #expect(container.tabViewModels.spotSearchViewModel === container.tabViewModels.spotSearchViewModel)
    }

    /// 컨테이너를 거치지 않는 팩토리는 여전히 매번 새 인스턴스를 만든다.
    /// push마다 초기화되어야 하는 화면(Detail/SpotAdd/Recommend/Riding)이 이 동작에 의존한다.
    @Test func factoriesStillProduceFreshInstancesForPerPushScreens() {
        #expect(DependencyProvider.makeDetailViewModel() !== DependencyProvider.makeDetailViewModel())
        #expect(DependencyProvider.makeRidingViewModel() !== DependencyProvider.makeRidingViewModel())
    }
}
