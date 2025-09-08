import SwiftUI

struct ImageZoomView: View {
    @EnvironmentObject var modalManager: ModalManager
    
    let imageUrl: String
    let title: String?
    
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        ZStack {
            // 배경
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    //                    modalManager.hideImageZoom()
                }
            
            AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .clipped()
                //                    .frame(maxHeight: 512)
            } placeholder: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } // :AsyncImag
            
            VStack(alignment: .center, spacing:0) {
                HStack(alignment: .top, spacing: 0) {
                    Spacer()
                    
                    if let title = title {
                        Text(title)
                            .foregroundColor(.white)
                            .font(.pretendardMedium(size: 18))
                    }
                    
                    Spacer()
                } // : HStack
                .frame(height: 56)
                .padding(.top, SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea)-23)
                .overlay(alignment: .bottomLeading){
                    // 닫기 버튼
                    Button(action: {
                        modalManager.hideImageZoom()
                    }) {
                        Image("icon_chevron-left (1)")
                            .frame(height: 56)
                            .frame(width: 56)
                            .cornerRadius(30)
                    }
                }
                
                Spacer()
            } // :VStack
        }
    }
}
