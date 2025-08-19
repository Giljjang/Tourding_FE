//
//  SpotSearchView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI

struct SpotSearchView: View {
    @StateObject private var viewModel = DestinationSearchViewModel()

    var body: some View {
        VStack{
            headerSpot
        }
    }
}

#Preview {
    SpotSearchView()
}



//MARK: - View

private var headerSpot: some View {
        HStack(spacing:0){
            VStack(alignment: .leading) {
                
                Text("스팟 탐색")
                    .font(.pretendardSemiBold(size: 26))
                    .foregroundColor(Color.gray6)
                Text("새로운 여행지를 찾아볼까요?")
                    .font(.pretendardMedium(size: 16))
                    .foregroundColor(Color.gray4)
            }
            .padding(.leading, 16)
            
            Spacer()
            
            Image("searching spot")
                .frame(width: 126)
                .padding(.trailing, 28)
            
        } // : HStack
} // : headerText



private var searchView: some View {
    Text("Search")
}
