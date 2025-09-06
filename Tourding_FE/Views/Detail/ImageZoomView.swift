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
            
            if let title = title {
                VStack(alignment: .leading, spacing:0) {
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        
                        Text(title)
                            .foregroundColor(.white)
                            .font(.pretendardMedium(size: 18))
                        
                        Spacer()
                    } // : HStack
                    .padding(.top, SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea-7))
                    
                    Spacer()
                } // :VStack
            }
            
            // 닫기 버튼
            Button(action: {
                modalManager.hideImageZoom()
            }) {
                Image("icon_chevron-left (1)")
                    .padding(.vertical, 8)
                    .padding(.leading, 6)
                    .padding(.trailing, 10)
                    .cornerRadius(30)
            }
            .position(x: 36, y: SafeAreaUtils.getMultipliedSafeArea(topSafeArea: topSafeArea))
        }
    }
}
