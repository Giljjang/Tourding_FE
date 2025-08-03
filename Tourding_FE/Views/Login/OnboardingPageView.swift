//
//  LoginOnboarding.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/3/25.
//

struct OnboardingPageView: View {
    let index: Int
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 20) {
            ForEach(page.image_sub, id: \.self) { imageName in
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
            }

            Text(page.title)
                .font(index == 0 ? .pretendardMedium(size: 18) : .pretendardSemiBold(size: 26))
                .foregroundColor(.gray)

            ForEach(page.images, id: \.self) { imageName in
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 338)
            }
        }
    }
}
