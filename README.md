# 🚴‍♂️ Tourding

> 자전거 여행을 위한 올인원 서비스

자전거 여행을 준비할 때, 흩어진 정보를 하나하나 찾느라 번거로우셨나요?  
라이딩 중, 근처 편의시설을 급하게 찾아본 경험이 있으신가요?

**투어딩**은 이러한 불편을 해결하기 위해 라이딩 스팟 정보 수집부터 나만의 코스 제작과 길 안내까지 지원하는 서비스예요.

투어딩과 함께 간편하고 즐거운 자전거 여행을 떠나보세요!

## ✨ 주요 기능

### 🗺️ 라이딩 코스 생성
- 출발·도착지를 입력하고 라이딩 중 들르고 싶은 스팟을 코스에 추가
- 자연, 인문, 레포츠, 쇼핑, 음식, 숙박 등 다양한 카테고리의 스팟 정보 제공
- 나만의 맞춤형 라이딩 루트 제작

### 🧭 라이딩 길 안내
- 제작한 코스로 라이딩을 시작하면 실시간 길 안내 제공
- 라이딩 중 현재 위치 근처 편의시설도 바로 확인 가능
- 네이버 지도 기반 정확한 내비게이션

### 🔍 스팟 탐색
- 지역·테마별 원하는 여행 스팟을 탐색
- 내 위치 근처의 추천 스팟 확인
- 카카오 로컬 API를 활용한 정확한 장소 검색

## 🛠️ 기술 스택

### Frontend
- **SwiftUI** - iOS 네이티브 UI 프레임워크
- **Combine** - 반응형 프로그래밍
- **MVVM Architecture** - 깔끔한 코드 구조

### Map & Navigation
- **네이버 지도 SDK** - 지도 표시 및 내비게이션
- **NMap** - 실시간 위치 추적

### Authentication
- **카카오 로그인 SDK** - 소셜 로그인
- **Keychain** - 안전한 토큰 저장

### Network
- **URLSession** - REST API 통신
- **JSON** - 데이터 직렬화/역직렬화

## 📱 앱 구조

```
Tourding_FE/
├── App/                    # 앱 진입점 및 의존성 주입
├── Views/                  # SwiftUI 뷰 컴포넌트
│   ├── Home/              # 홈 화면
│   ├── Riding/            # 라이딩 화면
│   ├── SpotSearch/        # 스팟 검색
│   ├── Detail/            # 상세 정보
│   └── Login/             # 로그인
├── ViewModels/            # MVVM 뷰모델
├── Model/                 # 데이터 모델
├── Network/               # 네트워크 레이어
├── Repository/            # 데이터 저장소
├── Utils/                 # 유틸리티
└── Resources/             # 리소스 파일
```

## 🚀 시작하기

### 요구사항
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### 설치 및 실행

1. **저장소 클론**
   ```bash
   git clone https://github.com/your-username/Tourding_FE.git
   cd Tourding_FE
   ```

2. **의존성 설치**
   - Xcode에서 프로젝트 열기
   - Swift Package Manager를 통해 자동으로 의존성 설치

3. **API 키 설정**
   - `Config.xcconfig` 파일에서 다음 키들을 설정:
     - `NAVER_APP_KEY`: 네이버 지도 API 키
     - `KAKAO_NATIVE_APP_KEY`: 카카오 네이티브 앱 키
     - `KAKAO_REST_API_KEY`: 카카오 REST API 키
     - `BASE_URL`: 백엔드 서버 URL

4. **빌드 및 실행**
   - Xcode에서 프로젝트 빌드
   - 시뮬레이터 또는 실제 기기에서 실행

## 📋 주요 화면

- **홈**: 지도 기반 메인 화면, 코스 생성 시작점
- **라이딩**: 실시간 내비게이션 및 라이딩 모드
- **스팟 검색**: 장소 검색 및 필터링
- **상세 정보**: 선택한 스팟의 자세한 정보
- **마이페이지**: 사용자 정보 및 설정

## 🔧 개발 환경 설정

### 필요한 API 키
1. **네이버 지도 API**
   - [네이버 클라우드 플랫폼](https://www.ncloud.com/)에서 발급
   
2. **카카오 로그인 API**
   - [카카오 개발자 콘솔](https://developers.kakao.com/)에서 발급

### 환경 변수 설정
`Config.xcconfig` 파일에 API 키들을 설정하세요:

```xcconfig
NAVER_APP_KEY = your_naver_app_key
KAKAO_NATIVE_APP_KEY = your_kakao_native_key
KAKAO_REST_API_KEY = your_kakao_rest_key
BASE_URL = your_backend_url
```

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해 주세요.

---

**투어딩**과 함께 즐거운 자전거 여행을 떠나보세요! 🚴‍♀️✨


