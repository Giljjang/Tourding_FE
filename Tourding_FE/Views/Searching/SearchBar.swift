//
//  SearchBarView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var hasSearched: Bool // 검색 실행 여부 추적
    var onSubmit: (() -> Void)? = nil
    var onTextChange: (() -> Void)? = nil // 텍스트 변경 콜백 추가

    var body: some View {
        HStack {
            TextField(
                "어디로 떠나볼까요?",
                text: $text,
                prompt: Text("어디로 떠나볼까요?")
                    .foregroundColor(.gray2)
                    .font(.pretendardMedium(size: 16))
            )
            .frame(height: 26)
            .submitLabel(.search)
            .onSubmit {
                onSubmit?()
                hideKeyboard()
            }
            .onChange(of: text) { newValue in
                // onSubmit이 호출된 직후에는 onChange를 무시
                if !newValue.isEmpty {
                    onTextChange?()
                }
            }
            .foregroundColor(.gray6)
            .font(.pretendardMedium(size: 16))
            .padding(.leading, 16)
            .padding(.vertical, 12)

            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                    hasSearched = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding(.trailing, 16)
            } else {
                EmptyView()
            }
        }
        .foregroundColor(Color.gray6)
        .background(Color.gray1)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    StatefulPreviewWrapper("") { text in
        @State var hasSearched = false
        return SearchBar(text: text, hasSearched: $hasSearched)
    }
}

struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
    @State private var value: Value
    private var content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
