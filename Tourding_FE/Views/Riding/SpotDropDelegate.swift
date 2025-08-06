//
//  SpotDropDelegate.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/6/25.
//

import Foundation
import SwiftUI

struct SpotDropDelegate: DropDelegate {
    @ObservedObject private var ridingViewModel: RidingViewModel
    
    let currentItem: RidingSpotModel
    @Binding var draggedSpot: RidingSpotModel?
    
    init(
        ridingViewModel: RidingViewModel,
        currentItem: RidingSpotModel,
        draggedSpot: Binding<RidingSpotModel?>
    ) {
        self.ridingViewModel = ridingViewModel
        self.currentItem = currentItem
        self._draggedSpot = draggedSpot // Binding 프로퍼티는 _ 붙여서 주입
    }
    
    // 드랍에서 벗어났을 때
    func dropExited(info: DropInfo) {
    }
    
    // 드랍 처리
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    // 드랍 변경
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return nil
    }
    
    // 드랍 유효 여부
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    // 드랍 시작
    func dropEntered(info: DropInfo) {
        guard let draggedSpot = self.draggedSpot else { return }
        
        // 드래깅된 아이템이랑 현재 내 아이템과 다를 경우
        if draggedSpot != currentItem {
            let from = ridingViewModel.spotList.firstIndex(of: draggedSpot)!
            let to = ridingViewModel.spotList.firstIndex(of:currentItem)!
            withAnimation {
                ridingViewModel.spotList.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
    
}
