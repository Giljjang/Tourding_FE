//
//  SearchBarView.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/7/25.
//
import SwiftUI

struct SearchBar: View {
    
    @Binding var text: String

    var body: some View {
        HStack {
            HStack {
                TextField(
                    "어디로 떠나볼까요?",
                    text: $text,
                    prompt: Text("어디로 떠나볼까요?")
                        .foregroundColor(.gray2)
                        .font(.pretendardMedium(size: 16))
                )
                .frame(height: 26)
                .foregroundColor(.gray6)
                .font(.pretendardMedium(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                } else {
                    EmptyView()
                }
            }
            .foregroundColor(Color.gray6)
            .background(Color.gray1)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

#Preview {
    StatefulPreviewWrapper("") { SearchBar(text: $0) }
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
