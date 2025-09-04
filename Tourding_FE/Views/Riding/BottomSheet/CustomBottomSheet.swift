//
//  CustomBottomSheet.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/6/25.
//

import SwiftUI
import NMapsMap

// MARK: - 바텀 시트 위치 열거형
enum BottomSheetPosition: CaseIterable {
    case small   // 하드코딩 유지
    case medium  // 동적 계산
    case large   // 동적 계산
    
    func height(screenHeight: CGFloat, isRiding: Bool = false) -> CGFloat {
        switch self {
        case .small:
            return isRiding ? 85 : 178
        case .medium:
            return screenHeight * 0.5
        case .large:
            return screenHeight * 0.8
        }
    }
}

// MARK: - 커스텀 바텀 시트
struct CustomBottomSheet<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let screenHeight: CGFloat
    let isRiding: Bool
    let locationManager: LocationManager?
    let mapView: NMFMapView?
    
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
        currentPosition: Binding<BottomSheetPosition>,
        isRiding: Bool = false,
        locationManager: LocationManager? = nil,
        mapView: NMFMapView? = nil
    ) {
        self.content = content
        self.screenHeight = screenHeight
        self._currentPosition = currentPosition
        self.isRiding = isRiding
        self.locationManager = locationManager
        self.mapView = mapView
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
//                        .frame(maxWidth: .infinity)
                        .frame(height: currentPosition.height(screenHeight: screenHeight, isRiding: isRiding))
                        .background(Color.white)
                    
                    Spacer()
                }
                .frame(height: screenHeight)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .offset(y: offset)
                .gesture(dragGesture(geometry: geometry))
                
                // moveToLocationButton - 바텀시트 외부에 배치
                if currentPosition != .large {
                    moveToLocationButton
                        .position(
                            x: 40,
                            y: offset - 30 // offset 사용으로 실시간 반영
                        )
                        .animation(.easeInOut(duration: animationDuration), value: currentPosition)
                } //: if
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onAppear {
            // 초기 위치 설정
            offset = screenHeight - currentPosition.height(screenHeight: screenHeight, isRiding: isRiding)
        }
    }
    
    //MARK: - View
    private var moveToLocationButton: some View {
        Button(action: {
            // 위치 이동 액션
            if let locationManager = locationManager, let mapView = mapView {
                locationManager.moveToCurrentLocation(on: mapView)
            }
        }) {
            VStack(spacing: 0) {
                Image("myPosition")
            }
            .frame(width: 40, height: 40)
            .background(.white)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                offset = max(0, min(screenHeight - BottomSheetPosition.small.height(screenHeight: screenHeight, isRiding: isRiding), newOffset))
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
        let targetOffset = screenHeight - position.height(screenHeight: screenHeight, isRiding: isRiding)
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            offset = targetOffset
        }
    }
}
