//
//  SearchTagView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 10/18/25.
//

import SwiftUI

// 1) 모델 + 더미 데이터
struct SpotCategoryNew: Identifiable, Hashable {
    let id: Int
    let title: String
    let sfSymbol: String
}

let spotCategories: [SpotCategoryNew] = [
    .init(id: 0, title: "전체",   sfSymbol: "spot_all"),
    .init(id: 1, title: "자연", sfSymbol: "nature"),
    .init(id: 2, title: "인문", sfSymbol: "humon"),
    .init(id: 3, title: "레포츠", sfSymbol: "leport"),
    .init(id: 4, title: "쇼핑", sfSymbol: "shoping"),
    .init(id: 5, title: "음식",  sfSymbol: "food"),
    .init(id: 6, title: "숙박",  sfSymbol: "sleep"),
]

// 2) 태그 버튼 컴포넌트
struct CategoryChipNew: View {
    let item: SpotCategoryNew
    let isSelected: Bool
    let isFromeHome: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isFromeHome ? Color.white : Color.gray1)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.main : .clear, lineWidth: 2)
                        )
                    Image(item.sfSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                Text(item.title)
                    .font(.pretendardMedium(size: 13))
                    .foregroundColor(isSelected ? Color.gray6 : Color.gray3)
                    .frame(height: 16)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
    }
}

// 3) 가로 스크롤 뷰
struct SearchTagView: View {
    @Binding var selectedCategoryID: Int
    var fromeHome: Bool
    var onSelect: ((SpotCategoryNew) -> Void)? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 9) {
                ForEach(spotCategories) { cat in
                    CategoryChipNew(item: cat, isSelected: selectedCategoryID == cat.id, isFromeHome: fromeHome) {
                        selectedCategoryID = cat.id
                        onSelect?(cat)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 1)
            .frame(maxHeight: 80)
        }
    }
}

// 미리보기(선택)
//#Preview
//struct SearchTagView_Previews: PreviewProvider {
//    static var previews: some View {
//        StatefulPreviewWrapper(0) { binding in
//            SearchTagView(selectedCategoryID: binding)
//        }
//    }
//}
//
//// 프리뷰용 바인딩 도우미
//struct StatefulPreviewWrapper<Value: MutableCollection & RandomAccessCollection, C: View> { }
//struct StatefulPreviewWrapper<Value, Content: View>: View {
//    @State var value: Value
//    var content: (Binding<Value>) -> Content
//    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
//        _value = State(initialValue: value)
//        self.content = content
//    }
//    var body: some View { content($value) }
//}
