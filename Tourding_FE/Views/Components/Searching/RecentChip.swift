//
//  RecentChip.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/17/25.
//

import SwiftUI

struct RecentChip: View {
    let title: String
    var onTap: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.pretendardMedium(size: 14))
                .foregroundColor(.gray4)
                .lineLimit(1)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray3)
                    .padding(4)
                    .clipShape(Circle())
            }.buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.leading, 14)
        .padding(.trailing, 11)
        .background(Color.gray1)
        .cornerRadius(12)
        .onTapGesture { onTap() }
        .contentShape(Rectangle())
    }
}
