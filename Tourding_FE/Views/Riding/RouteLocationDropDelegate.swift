//
//  RouteLocationDropDelegate.swift
//  Tourding_FE
//
//  Created by GPT on 9/1/25.
//

import Foundation
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
    
    func dropExited(info: DropInfo) {
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }

        Task {
            // ToDo
//            await ridingViewModel.getRoutePathAPI()
        }
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return nil
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else { return }
        
        // 시작(0)과 도착(마지막) 고정: 재정렬 대상은 1..<(count-1)
        let items = ridingViewModel.routeLocation
        guard items.count >= 3 else { return }
        
        if draggedItem.sequenceNum != currentItem.sequenceNum {
            guard let from = items.firstIndex(where: { $0.sequenceNum == draggedItem.sequenceNum }),
                  let to = items.firstIndex(where: { $0.sequenceNum == currentItem.sequenceNum }) else { return }
            // from/to가 1..<(count-1) 범위인지 확인
            if from > 0 && from < items.count - 1 && to > 0 && to < items.count - 1 {
                withAnimation {
                    ridingViewModel.routeLocation.move(
                        fromOffsets: IndexSet(integer: from),
                        toOffset: to > from ? to + 1 : to
                    )
                }
            }
        }
    }
}


