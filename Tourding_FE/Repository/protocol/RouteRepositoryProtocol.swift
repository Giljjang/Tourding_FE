//
//  RouteRepositoryProtocol.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/30/25.
//

import Foundation

protocol RouteRepositoryProtocol {
    /// 서버는 POST 응답으로 경로 전체(요약·guides·paths·locations)를 돌려준다.
    /// 그걸 버리고 다시 GET하면 같은 재계산이 한 번 더 일어난다.
    @discardableResult
    func postRoutes(requestBody: RequestRouteModel) async throws -> RouteGuideResponse
    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel]
    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws  -> [LocationNameModel]
    /// **현재 앱에서 호출하지 않는다.**
    ///
    /// `POST /routes` 응답에 `guides`가 그대로 들어 있어(같은 `RouteGuideRespDto`,
    /// 실측 응답이 바이트 단위로 동일) 라이딩 시작이 그 응답을 재사용한다.
    /// 이 엔드포인트를 따로 부르면 같은 ORS 재계산이 한 번 더 일어난다.
    ///
    /// 서버에는 살아 있으므로 프로토콜에서 지우지 않았다. 다시 쓰려면
    /// 응답이 배열이 아니라 객체라는 점에 주의할 것 —
    /// 배열로 디코딩해 안내가 통째로 사라진 적이 있다 (`RouteGuideResponseTests`).
    func getRoutesGuide(userId: Int, isUsed: Bool) async throws  -> [GuideModel]
    
    func getRoutes(userId: Int, isUsed: Bool) async throws  -> RoutesModel
    func getRoutesRidingRecommend(pageNum:Int) async throws -> [RouteRidingRecommendModel]
    func postRoutesByName(requestBody:ReqRoutesByNameModel) async throws -> RoutesModel

    /// GET /routes — 요약·가이드·경로선·장소를 한 번에 반환한다.
    /// 개별 엔드포인트를 각각 부르면 서버가 같은 경로를 여러 번 재계산한다.
    func getRouteBundle(userId: Int, isUsed: Bool) async throws -> RouteGuideResponse
}
