//
//  RidingViewModel+RouteReorder.swift
//  Tourding_FE
//
//  경유지 드래그앤드롭 순서 변경 — 지도 동기화 및 서버 POST
//

import Foundation

extension RidingViewModel {

    // MARK: - 지도 동기화

    /// routeLocation 배열 순서대로 마커·아이콘 반영 후 지도 갱신
    @MainActor
    func syncMapAfterRouteReorder(_ locationData: [LocationNameModel]) {
        applyRouteLocationMarkers(from: locationData)
        refreshMapDisplay()
    }

    // MARK: - 서버 저장

    /// performDrop 시 즉시 POST (디바운스 Task 취소)
    @MainActor
    func persistRouteOrderAfterReorder() async {
        cancelScheduledReorderPersist()
        let ordered = routeLocation
        await postRouteDragNDropAPI(locationData: ordered)
        await getRoutePathAPI()
        syncMapAfterRouteReorder(ordered)
    }

    /// ScrollView DnD에서 performDrop 미호출 대비 — dropEntered 후 디바운스 POST
    @MainActor
    func schedulePersistRouteOrderAfterReorder() {
        reorderPersistTask?.cancel()
        reorderPersistTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await persistRouteOrderAfterReorder()
        }
    }

    @MainActor
    func cancelScheduledReorderPersist() {
        reorderPersistTask?.cancel()
        reorderPersistTask = nil
    }
}
