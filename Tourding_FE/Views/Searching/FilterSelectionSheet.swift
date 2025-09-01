//
//  FilterSelectionSheet.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/31/25.
//

import SwiftUI

struct FilterModal: View {
    @Binding var selectedRegion: String?
    @Binding var selectedTheme: String?
    @Binding var isPresented: Bool
    let onFilterApplied: (String?, String?) -> Void  // 콜백 추가
    
    // 임시 선택값들 (모달 내에서만 사용)
    @State private var tempSelectedRegion: String?
    @State private var tempSelectedTheme: String?
    
    let regions = ["서울", "인천", "경기", "대전", "세종", "충청", "대구", "경상", "울산", "부산", "광주", "전라", "강원", "제주"]
    let themes = ["자연", "인문(문화/예술/역사)", "레포츠", "쇼핑", "음식", "숙박"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더
                    headerSection
                    
                    // 지역별 섹션
                    regionSection
                    
                    // 테마별 섹션
                    themeSection
                }
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            // 완료 버튼
            completeButton
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .onAppear {
            // 모달이 열릴 때 현재 선택값으로 임시값 초기화
            tempSelectedRegion = selectedRegion
            tempSelectedTheme = selectedTheme
        }
    }
    
    // MARK: - 헤더 섹션
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("필터")
                .font(.pretendardSemiBold(size: 20))
                .foregroundColor(.gray6)
                .padding(.horizontal, 16)
            
            Divider()
                .foregroundColor(.gray1)
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 지역별 섹션
    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("지역별")
                .font(.pretendardMedium(size: 16))
                .foregroundColor(.gray6)
                .padding(.horizontal, 20)
            
            FlexibleView(
                data: regions,
                spacing: 12,
                alignment: .leading
            ) { region in
                regionChip(region)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 테마별 섹션
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("테마별")
                .font(.pretendardMedium(size: 16))
                .foregroundColor(.gray6)
                .padding(.horizontal, 20)
            
            FlexibleView(
                data: themes,
                spacing: 12,
                alignment: .leading
            ) { theme in
                themeChip(theme)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 완료 버튼
    private var completeButton: some View {
           Button(action: {
               // 바인딩 업데이트
               selectedRegion = tempSelectedRegion
               selectedTheme = tempSelectedTheme
               
               // 콜백 호출 (서버 검색 실행)
               onFilterApplied(tempSelectedRegion, tempSelectedTheme)
               
               // 모달 닫기
               isPresented = false
           }) {
               Text("선택 완료")
                   .font(.pretendardSemiBold(size: 16))
                   .foregroundColor(.white)
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 16)
                   .background(Color.gray5)
                   .cornerRadius(10)
           }
           .padding(.horizontal, 16)
           .padding(.bottom, 20)
       }
    
    // MARK: - 지역 칩
    private func regionChip(_ region: String) -> some View {
        Button(action: {
            tempSelectedRegion = tempSelectedRegion == region ? nil : region
        }) {
            Text(region)
                .font(.pretendardMedium(size: 14))
                .foregroundColor(tempSelectedRegion == region ? .white : .gray4)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    tempSelectedRegion == region ?
                    Color.mainCalm : Color.gray1
                )
                .cornerRadius(12)
        }
    }
    
    // MARK: - 테마 칩
    private func themeChip(_ theme: String) -> some View {
        Button(action: {
            tempSelectedTheme = tempSelectedTheme == theme ? nil : theme
        }) {
            Text(theme)
                .font(.pretendardMedium(size: 14))
                .foregroundColor(tempSelectedTheme == theme ? .white : .gray4)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    tempSelectedTheme == theme ?
                    Color.mainCalm : Color.gray1
                )
                .cornerRadius(12)
        }
    }
}

// MARK: - FlexibleView (Chip 스타일 레이아웃)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var elementsSize: [Data.Element: CGSize] = [:]
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            if elementsSize.count == data.count {
                _FlexibleView(
                    availableWidth: availableWidth,
                    data: data,
                    elementsSize: elementsSize,
                    spacing: spacing,
                    alignment: alignment,
                    content: content
                )
            } else {
                // 먼저 각 요소의 실제 크기를 측정
                ZStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, element in
                        content(element)
                            .fixedSize()
                            .opacity(0)
                            .readSize { size in
                                DispatchQueue.main.async {
                                    elementsSize[element] = size
                                }
                            }
                    }
                }
            }
        }
    }
}

struct _FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let elementsSize: [Data.Element: CGSize]
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                    }
                    if alignment == .leading {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
    
    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementWidth = elementsSize[element]?.width ?? 0
            
            if remainingWidth >= elementWidth + spacing || rows[currentRow].isEmpty {
                rows[currentRow].append(element)
                remainingWidth -= elementWidth + spacing
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth - elementWidth - spacing
            }
        }
        
        return rows
    }
}

// MARK: - Size Reader Helper
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
//
//#Preview {
//    FilterModal(
//        selectedRegion: .constant("서울"),
//        selectedTheme: .constant("자연"),
//        isPresented: .constant(true),
//        onFilterApplied: <#(String?, String?) -> Void#>
//    )
//}
