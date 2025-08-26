//
//  CustomBottomSheet.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/6/25.
//

import SwiftUI

// MARK: - 바텀 시트 위치 열거형
enum BottomSheetPosition: CaseIterable {
    case small   // 188
    case medium  // 455 (기본값)
    case large   // 706
    
    var height: CGFloat {
        switch self {
        case .small: return 158 //188
        case .medium: return 425 // 455
        case .large: return 676 // 706
        }
    }
}

// MARK: - 커스텀 바텀 시트
struct CustomBottomSheet<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let screenHeight: CGFloat
    
    @State private var offset: CGFloat = 0
    @Binding private var currentPosition: BottomSheetPosition
    @State private var isDragging = false
    @State private var dragStartOffset: CGFloat = 0
    
    // MARK: - Configuration
    private let dragThreshold: CGFloat = 50
    private let animationDuration: Double = 0.3
    private let dragButtonHeight: CGFloat = 4
    private let dragButtonWidth: CGFloat = 40
    
    // MARK: - Initializer
    init(
        content: Content,
        screenHeight: CGFloat,
        currentPosition: Binding<BottomSheetPosition>
    ) {
        self.content = content
        self.screenHeight = screenHeight
        self._currentPosition = currentPosition
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 바텀 시트
                VStack(spacing: 0) {
                    // 드래그 핸들
                    dragHandle
                    
                    // 컨텐츠
                    content
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                }
                .frame(height: screenHeight)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
                .offset(y: offset)
                .gesture(dragGesture(geometry: geometry))
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            // 초기 위치 설정
            offset = screenHeight - currentPosition.height
        }
    }
    
    // MARK: - Drag Handle
    private var dragHandle: some View {
        VStack(spacing: 0) {
            // 드래그 버튼
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray2)
                .frame(width: dragButtonWidth, height: dragButtonHeight)
            
        }
        .padding(.top, 13)
        .padding(.bottom, 11)
    }
    
    // MARK: - Drag Gesture
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragStartOffset = offset
                }
                
                // 드래그 시작 시점의 offset에서 변화량만큼 이동
                let newOffset = dragStartOffset + value.translation.height
                offset = max(0, min(screenHeight - BottomSheetPosition.small.height, newOffset))
            }
            .onEnded { value in
                isDragging = false
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let translation = value.translation.height
                
                // 스냅 로직 - 현재 위치를 기준으로 결정
                let targetPosition = determineTargetPosition(
                    translation: translation,
                    velocity: velocity,
                    currentPosition: currentPosition
                )
                
                animateToPosition(targetPosition)
            }
    }
    
    // MARK: - Snap Logic
    private func determineTargetPosition(translation: CGFloat, velocity: CGFloat, currentPosition: BottomSheetPosition) -> BottomSheetPosition {
        let positions = BottomSheetPosition.allCases
        let currentIndex = positions.firstIndex(of: currentPosition) ?? 1
        
        // 드래그 방향과 속도에 따른 위치 결정
        if abs(translation) < dragThreshold {
            // 임계값보다 작은 드래그는 현재 위치 유지
            return currentPosition
        }
        
        if translation > 0 {
            // 아래로 드래그 (크기 감소)
            if currentIndex > 0 {
                return positions[currentIndex - 1]
            }
        } else {
            // 위로 드래그 (크기 증가)
            if currentIndex < positions.count - 1 {
                return positions[currentIndex + 1]
            }
        }
        
        return currentPosition
    }
    
    // MARK: - Animation
    private func animateToPosition(_ position: BottomSheetPosition) {
        currentPosition = position
        let targetOffset = screenHeight - position.height
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            offset = targetOffset
        }
    }
}
