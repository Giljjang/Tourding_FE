//
//  RouteLocationDropDelegate.swift
//  Tourding_FE
//
//  Created by GPT on 9/1/25.
//

import SwiftUI

struct RouteLocationDropDelegate: DropDelegate {
    @ObservedObject private var ridingViewModel: RidingViewModel

    let currentItem: LocationNameModel
    @Binding var draggedItem: LocationNameModel?

    init(
        ridingViewModel: RidingViewModel,
        currentItem: LocationNameModel,
        draggedItem: Binding<LocationNameModel?>
    ) {
        self.ridingViewModel = ridingViewModel
        self.currentItem = currentItem
        self._draggedItem = draggedItem
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        Task { @MainActor in
            await ridingViewModel.persistRouteOrderAfterReorder()
        }
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              let reordered = Self.reorderedRoute(
                  from: ridingViewModel.routeLocation,
                  draggedItem: draggedItem,
                  targetItem: currentItem
              ) else { return }

        withAnimation {
            ridingViewModel.routeLocation = reordered
        }

        Task { @MainActor in
            ridingViewModel.syncMapAfterRouteReorder(reordered)
            ridingViewModel.schedulePersistRouteOrderAfterReorder()
        }
    }

    /// 출발(0)·도착(last) 고정, 경유지만 재정렬
    private static func reorderedRoute(
        from items: [LocationNameModel],
        draggedItem: LocationNameModel,
        targetItem: LocationNameModel
    ) -> [LocationNameModel]? {
        guard items.count >= 3,
              draggedItem.sequenceNum != targetItem.sequenceNum,
              let from = items.firstIndex(where: { $0.sequenceNum == draggedItem.sequenceNum }),
              let to = items.firstIndex(where: { $0.sequenceNum == targetItem.sequenceNum }),
              from > 0, from < items.count - 1,
              to > 0, to < items.count - 1 else { return nil }

        var reordered = items
        reordered.move(
            fromOffsets: IndexSet(integer: from),
            toOffset: to > from ? to + 1 : to
        )
        return reordered
    }
}
