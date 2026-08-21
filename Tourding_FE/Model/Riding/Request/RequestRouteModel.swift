//
//  RequestRouteModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

/// POST /routes 요청 본문.
///
/// ⚠️ 좌표는 **경도,위도** 순이다.
/// `LocationManager.getCurrentLocationString()`이 만드는 문자열(위도,경도 — 편의시설 API용)과 반대이므로
/// 새 조립부를 쓸 때 혼동하지 말 것. 규약은 `RouteAddRequestTests`가 고정한다.
///
/// `wayPoints`/`typeCode`/`contentId`/`contentTypeId`는 **경유지만** 담으며 개수가 서로 같아야 한다.
/// `locateName`은 출발·도착을 포함한 전체다.
struct RequestRouteModel: Codable, Equatable {
    let userId: Int
    let start: String // "경도,위도"
    let goal: String // "경도,위도"
    var wayPoints: String = "" // "경도,위도|경도,위도"
    let locateName: String // "출발,경유,경유,도착"
    let typeCode: String // 경유지 관광 카테고리 코드 "A01,A02"
    let contentId: String // 경유지 콘텐츠 ID "630741,2766859"
    let contentTypeId: String // 경유지 관광타입 "12,39"
    let isUsed: Bool
    /// 라이딩 스타일. **반드시 실어야 한다.**
    ///
    /// 서버는 이 값이 없으면 **디폴트로 계산한다** — 저장된 프로필을 꺼내 쓰지 않는다.
    /// 따라서 nil은 "서버가 알아서 함"이 아니라 **사용자 설정이 무시됨**을 뜻한다.
    /// 값은 `RidingProfileStore`에서 얻는다.
    ///
    /// 그래도 옵셔널인 이유는 한 번도 프로필을 못 읽은 경우뿐이다.
    /// (`null`을 보내지 않고 키를 빼기 위해 옵셔널로 둔다 — 합성 인코더가 생략해 준다.)
    var routeOption: RouteOptionModel? = nil
}
