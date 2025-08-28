//
//  ModalManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/4/25.
//

import Foundation

enum ShowViewType {
    case tabView
    case ridingView
    case ridingNextView
}

final class ModalManager: ObservableObject {
    // 일반적인 모달
    @Published var isPresented: Bool = false
    
    @Published var title: String = ""
    @Published var subText: String = ""
    @Published var activeText: String = ""
    @Published var showView: ShowViewType = .tabView
    
    var onCancel: (() -> Void)?
    var onActive: (() -> Void)?
    
    // 토스트 메시지
    @Published var isToastMessage: Bool = false
    
    func showModal(
        title: String,
        subText: String,
        activeText: String,
        showView: ShowViewType,
        onCancel: @escaping () -> Void,
        onActive: @escaping () -> Void
    ) {
        self.title = title
        self.subText = subText
        self.activeText = activeText
        self.showView = showView
        self.onCancel = onCancel
        self.onActive = onActive
        self.isPresented = true
    }
    
    func hideModal() {
        self.isPresented = false
        self.onCancel = nil
        self.onActive = nil
    }
}
