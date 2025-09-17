//
//  ServiceVeiw.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/5/25.
//

import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            
            // MARK: - Top Navigation Bar
            ZStack {
                HStack {
                    Button(action: {
                        navigationManager.pop()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.gray5)
                            .padding()
                    }
                    Spacer()
                }

                Text("개인정보처리방침")
                    .font(.pretendardMedium(size: 18))
                    .foregroundColor(Color.gray5)
            }
            .frame(height: 56)
            .padding(.bottom, 29)
            
            // MARK: - Terms Content
            ScrollView {
                VStack(alignment: .leading) {
                        
                        Text(dummyTermsText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundColor(Color.gray4)
                            .lineSpacing(1.4)
                }
                .padding(22)
                .background(Color.gray1)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray2, lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .background(Color(.white).ignoresSafeArea())
        .navigationBarHidden(true)  // ✅ 시스템 네비게이션 바 숨김
        .interactiveDismissDisabled(false) // 네이티브 스와이프 백 제스처 활성화
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 왼쪽에서 오른쪽으로 스와이프 감지
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        print("👈 스와이프 뒤로가기 감지")
                        navigationManager.pop()
                    }
                }
        ) // :gesture
    }
}

// MARK: - 안전한 Preview
#Preview {
    NavigationStack {
        ServiceView()
            .environmentObject(NavigationManager())
    }
}

// Dummy Text
let dummyTermsText = """
< Tourding >은(는) 「개인정보 보호법」 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.

○ 이 개인정보처리방침은 2025년 9월 10일부터 적용됩니다.


제1조(개인정보의 처리 목적)

< Tourding >은(는) 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 「개인정보 보호법」 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원가입 및 관리
    - Apple 로그인, Kakao 로그인 등 제휴 로그인 제공에 따른 본인 식별·인증, 회원자격 유지·관리 목적으로 개인정보를 처리합니다.
2. 길찾기 가이드 제공
    - 사용자의 위치정보 및 길찾기 좌표를 기반으로 경로 안내 서비스를 제공합니다.


제2조(개인정보의 처리 및 보유 기간)

① *< Tourding >*은(는) 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다.

- 1. 회원가입 및 관리
    - 수집·이용 동의일로부터 5년까지 위 이용목적을 위하여 보유·이용됩니다.
    - 보유근거 : 「개인정보보호법」 제15조(개인정보의 수집·이용) 제1항
    - 관련법령 : 계약 또는 청약철회 등에 관한 기록(5년)
    - 예외사유 : 계정 탈퇴 시 지체 없이 파기
- 2. 길찾기 좌표 데이터
    - 사용자가 계정을 탈퇴할 때까지 보유·이용됩니다.


제3조(처리하는 개인정보의 항목)

① < Tourding >은(는) 다음의 개인정보 항목을 처리하고 있습니다.

- 1. 회원가입 및 관리
    - 필수항목 : 이름, 이메일, 로그인 ID(Apple/Kakao 계정 정보), 접속 로그
    - 선택항목 : 없음
- 2. 길찾기 가이드 제공
    - 필수항목 : 위치정보, 사용자가 저장한 길찾기 좌표 데이터


제4조(개인정보의 파기절차 및 파기방법)

① < Tourding >은(는) 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.

② 다만, 다른 법령에 따라 개인정보를 계속 보존하여야 하는 경우에는, 해당 법령에서 정한 항목과 기간에 한하여 별도의 데이터베이스(DB) 또는 보관장소에 분리하여 보존합니다.

③ 개인정보 파기의 절차 및 방법은 다음과 같습니다.

- 파기절차 : 파기 사유가 발생한 개인정보를 선정하고, 개인정보 보호책임자의 승인을 받아 개인정보를 파기합니다.
- 파기방법 :
    - 종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각을 통하여 파기합니다.
    - 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다.


제5조(정보주체와 법정대리인의 권리·의무 및 행사방법)

① 정보주체는 Tourding에 대해 언제든지 개인정보 열람·정정·삭제·처리정지 요구 등의 권리를 행사할 수 있습니다.

② 제1항에 따른 권리 행사는 「개인정보 보호법」 시행령 제41조제1항에 따라 서면, 전자우편 등을 통하여 하실 수 있으며, Tourding은 이에 대해 지체 없이 조치합니다.

③ 대리인을 통한 권리행사 시 별지 제11호 서식 위임장을 제출하셔야 합니다.

④ 개인정보 열람 및 처리정지 요구는 「개인정보 보호법」 제35조 제4항, 제37조 제2항에 의하여 제한될 수 있습니다.

⑤ 개인정보의 정정 및 삭제 요구는 다른 법령에서 그 개인정보가 수집 대상으로 명시되어 있는 경우에는 그 삭제를 요구할 수 없습니다.

⑥ Tourding은 권리 행사 요청자가 본인 또는 정당한 대리인인지 확인합니다.


제6조(개인정보의 안전성 확보조치)

< Tourding >은(는) 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.

1. 개인정보 접근 제한: 데이터베이스 접근권한 부여·변경·말소를 통해 개인정보 접근을 통제하며, 침입차단시스템을 이용하여 외부 무단 접근을 통제합니다.
2. 개인정보 암호화: 주요 개인정보(로그인 계정 식별자, 위치정보 등)는 암호화하여 저장·관리하며, 전송 시에도 암호화 통신을 적용합니다.
3. 보안 프로그램 설치: 해킹이나 악성코드에 대비하여 보안프로그램을 설치·갱신·점검하고 있습니다.
4. 로그 관리: 개인정보 처리 기록을 보관하고 위·변조되지 않도록 관리합니다.
5. 물리적 안전조치: 서버는 접근이 통제된 구역에 설치하여 물리적으로 보호합니다.


제7조(쿠키의 사용)

Tourding은 이용자의 정보를 저장하거나 수시로 불러오는 ‘쿠키(cookie)’를 사용하지 않습니다.


제8조(개인정보 보호책임자에 관한 사항)

① Tourding은 개인정보 처리에 관한 업무를 총괄하여 책임지고, 개인정보 보호와 관련한 불만처리 및 피해구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

② 이용자는 Tourding의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의를 아래 개인정보 보호책임자 및 담당부서로 문의할 수 있습니다.

개인정보 보호 책임자

• 성명 : 유재혁
• 직책 :개발자
• 연락처 :010-5685-0125, yoojh5685@gmail.com
※ 개인정보 보호 담당부서로 연결됩니다.


제9조(정보주체의 권익침해에 대한 구제방법)

정보주체는 개인정보침해로 인한 구제를 받기 위하여 아래 기관에 상담 등을 신청할 수 있습니다.

1. 개인정보분쟁조정위원회 : 1833-6972 ([www.kopico.go.kr](http://www.kopico.go.kr/))
2. 개인정보침해신고센터 : 118 (privacy.kisa.or.kr)
3. 대검찰청 : 1301 ([www.spo.go.kr](http://www.spo.go.kr/))
4. 경찰청 : 182 (ecrm.cyber.go.kr)

또한 「개인정보보호법」 제35조, 제36조, 제37조에 따른 요구에 대하여 공공기관의 처분 또는 부작위로 권리·이익을 침해받은 경우, 행정심판법에 따라 행정심판을 청구할 수 있습니다.

※ 중앙행정심판위원회([www.simpan.go.kr](http://www.simpan.go.kr/)) 참조


제10조(개인정보 처리방침 변경)

- 최초 제정일 : 2025년 9월 10일
- 최종 개정일 : 2025년 9월 10일
    
    이 개인정보처리방침은 2025년 9월 10일부터 적용됩니다.
"""
