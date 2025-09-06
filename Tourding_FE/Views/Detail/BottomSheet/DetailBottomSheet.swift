//
//  DetailBottomSheet.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import SwiftUI

// MARK: - 바텀 시트 위치 열거형
enum DetailBottomSheetPosition: CaseIterable {
    case standard
    case large
    
    func height(screenHeight: CGFloat) -> CGFloat {
        switch self {
        case .standard:
            return screenHeight * 0.6
        case .large:
            return screenHeight * 0.85
        }
    }
}

// MARK: - 커스텀 바텀 시트
struct DetailBottomSheet<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let screenHeight: CGFloat
    
    @Binding var currentPosition: DetailBottomSheetPosition
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragStartOffset: CGFloat = 0
    
    // MARK: - Configuration
    private let dragThreshold: CGFloat = 50
    private let animationDuration: Double = 0.3
    private let dragButtonHeight: CGFloat = 30
    private let dragButtonWidth: CGFloat = 60
    
    // MARK: - Initializer
    init(content: Content, screenHeight: CGFloat, currentPosition: Binding<DetailBottomSheetPosition>) {
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
                    
                    // 컨텐츠
                    content
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                }
                .frame(height: screenHeight)
                .cornerRadius(currentPosition != .large ? 16 : 0)
                .offset(y: offset)
                .gesture(dragGesture(geometry: geometry))
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            // 초기 위치 설정
            offset = screenHeight - currentPosition.height(screenHeight: screenHeight)
        }
        .onChange(of: currentPosition) { newPosition in
            // 외부에서 position이 변경될 때 애니메이션
            animateToPosition(newPosition)
        }
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
                offset = max(0, min(screenHeight - DetailBottomSheetPosition.standard.height(screenHeight: screenHeight), newOffset))
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
    private func determineTargetPosition(translation: CGFloat, velocity: CGFloat, currentPosition: DetailBottomSheetPosition) -> DetailBottomSheetPosition {
        let positions = DetailBottomSheetPosition.allCases
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
    private func animateToPosition(_ position: DetailBottomSheetPosition) {
        let targetOffset = screenHeight - position.height(screenHeight: screenHeight)
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            offset = targetOffset
        }
        
        // 애니메이션 완료 후 currentPosition 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            currentPosition = position
        }
    }
}

