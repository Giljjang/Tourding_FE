//
//  ModalManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/4/25.
//

import Foundation

final class ModalManager: ObservableObject {
    @Published var isPresented: Bool = false
    
    @Published var title: String = ""
    @Published var subText: String = ""
    @Published var activeText: String = ""
    
    @Published var onCancel: (() -> Void)?
    @Published var onActive: (() -> Void)?
    
    func showModal(
        title: String,
        subText: String,
        activeText: String,
        onCancel: @escaping () -> Void,
        onActive: @escaping () -> Void
    ) {
        self.title = title
        self.subText = subText
        self.activeText = activeText
        self.onCancel = onCancel
        self.onActive = onActive
        self.isPresented = true
    }
    
    func hideModal() {
        self.isPresented = false
    }
}
