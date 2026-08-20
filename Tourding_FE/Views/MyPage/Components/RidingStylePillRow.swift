//
//  RidingStylePillRow.swift
//  Tourding_FE
//
//  Created by Claude on 8/20/26.
//

import SwiftUI

struct RidingStylePillRow<Option: Identifiable & Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options) { option in
                RidingStylePillButton(
                    title: label(option),
                    isSelected: selection == option,
                    action: { selection = option }
                )
            }
        }
    }
}
