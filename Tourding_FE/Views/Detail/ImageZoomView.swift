import SwiftUI

struct ImageZoomView: View {
    @EnvironmentObject var modalManager: ModalManager
    
    let imageUrls: String
    
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
                    modalManager.hideImageZoom()
                }
            
            AsyncImage(url: URL(string: imageUrls ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .clipped()
            } placeholder: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } // :AsyncImag
            
            
            // 닫기 버튼
            Button(action: {
                modalManager.hideImageZoom()
            }) {
                Image("icon_chevron-left (1)")
                    .padding(.vertical, 8)
                    .padding(.leading, 6)
                    .padding(.trailing, 10)
                //                    .background(Color.white.opacity(0.2))
                    .cornerRadius(30)
            }
            .position(x: 36, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
        }
    }
}
