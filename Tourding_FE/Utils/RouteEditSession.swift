//
//  RouteEditSession.swift
//  Tourding_FE
//
//  지금 편집 중인 경로가 draft인지 최근 사용 경로인지.
//
//  라이딩 편집 화면은 둘 중 하나를 편집한다(`RidingRouteSource`).
//  그런데 스팟 추가·상세는 별도 ViewModel이라 그 사실을 몰랐고 **항상 draft**를 읽고 썼다.
//  최근 경로를 편집하며 스팟을 추가하면 draft에 저장돼 화면에 나타나지 않았다.
//
//  실측 로그:
//    GET  /routes?userId=49&isUsed=true              ← 편집 화면이 읽는 경로
//    GET  /routes/location-name?userId=49&isUsed=false  ← 스팟 추가가 읽는 경로
//    POST /routes  isUsed:false  경유지 5개            ← draft에 저장
//    GET  /routes?userId=49&isUsed=true → 경유지 2개    ← 추가가 사라짐
//
//  진입 경로가 여럿이라(`DestinationSearchView`를 거치기도 한다) `ViewType`으로 나르면
//  중간 화면까지 값을 이어야 한다. 대신 여기 한 곳에 기록해 공유한다 —
//  `RidingProfileStore`와 같은 방식이다.
//
//  회귀 방지 테스트: `RouteEditSessionTests`
//

import Foundation

protocol RouteEditSessionProviding: AnyObject {
    /// 지금 편집 중인 경로의 `isUsed`. 기본은 draft(false)다 —
    /// 홈에서 새 경로를 만드는 흐름이 그렇다.
    var isUsed: Bool { get }

    /// 라이딩 편집 화면에 들어갈 때 어느 경로인지 기록한다
    func beginEditing(isUsed: Bool)

    /// 편집 중인 경로에 **서버가 실제로 적용한** 스타일.
    ///
    /// 최근 경로를 이어서 갈 때는 이미 어떤 스타일로 계산돼 저장돼 있다.
    /// 스타일 화면이 유저 프로필을 보여주면 화면과 실제 경로가 어긋난다 —
    /// 실측 로그에서 경로는 `cycling-electric`인데 화면은 프로필의 `cycling-regular`였다.
    /// 서버가 안 내려주면 nil이고, 그때만 유저 프로필로 폴백한다.
    var appliedOption: RouteOptionModel? { get }

    /// 경로를 읽거나 다시 계산할 때마다 기록한다
    func recordAppliedOption(_ option: RouteOptionModel?)

    /// 세션 정리. 다음 사용자가 남의 최근 경로를 건드리지 않도록 draft로 되돌린다.
    func reset()
}

@MainActor
final class RouteEditSession: RouteEditSessionProviding {

    private(set) var isUsed: Bool = false
    private(set) var appliedOption: RouteOptionModel?

    func recordAppliedOption(_ option: RouteOptionModel?) {
        appliedOption = option
    }

    func beginEditing(isUsed: Bool) {
        self.isUsed = isUsed
    }

    func reset() {
        isUsed = false
        appliedOption = nil
    }
}
