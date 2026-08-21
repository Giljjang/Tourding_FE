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
- **드래그 앤 드롭**으로 경로 순서 자유롭게 변경

### 🧭 실시간 라이딩 네비게이션
- **실시간 위치 추적**: GPS 기반 정확한 현재 위치 추적
- **나침반 네비게이션**: 사용자가 바라보는 방향에 따라 카메라 자동 회전
- **지나간 마커 자동 제거**: 30m 임계값으로 지나간 경로 마커 자동 삭제
- **동적 카메라 피봇**: 바텀시트 높이에 따른 카메라 시점 자동 조정
- **편의시설 표시**: 화장실, 편의점 등 주변 편의시설 검색 및 표시

### 🎯 추천 코스 기능
- **다양한 테마**: 자연, 문화, 맛집, 힐링 등 다양한 테마별 추천 코스
- **상세 정보 제공**: 총 거리, 소요시간, 주요 포인트 정보
- **원클릭 적용**: 추천 코스를 바로 내 코스로 적용 가능

### 🔍 스팟 탐색 및 추가
- **카카오 로컬 API**: 정확한 장소 검색 및 정보 제공
- **실시간 필터링**: 카테고리별, 거리별 스팟 필터링
- **라이딩 중 스팟 추가**: 라이딩 중에도 새로운 스팟을 경로에 즉시 추가
- **최근 검색 기록**: 자주 찾는 장소 빠른 재검색

### 📍 고급 라이딩 기능
- **경로 백업/복원**: 라이딩 중 원본 경로 데이터 자동 백업 및 복원
- **비정상 종료 복구**: 앱 종료 후 재시작 시 라이딩 상태 자동 복구
- **포그라운드 복귀 처리**: 앱 백그라운드에서 복귀 시 지도 데이터 자동 새로고침
- **메모리 최적화**: 효율적인 리소스 관리로 부드러운 라이딩 경험

## 🛠️ 기술 스택

### Frontend
- **SwiftUI** - iOS 네이티브 UI 프레임워크
- **MVVM Architecture** - 깔끔한 코드 구조
- **Dependency Injection** - 의존성 주입을 통한 테스트 가능한 구조

### Map & Navigation
- **네이버 지도 SDK (NMFMapView)** - 고성능 지도 표시 및 내비게이션 (헤딩-업 회전, 라이딩 시작 시 자동 확대·종료 시 복원)
- **NMap** - 실시간 위치 추적 및 나침반 기능 (방위 판정은 `HeadingResolver` 한 곳, 진북 기준)
- **Core Location** - 정확한 GPS 위치 서비스
- **Custom Location Manager** - 효율적인 위치 추적 관리

### Authentication & Security
- **카카오 로그인 SDK** - 소셜 로그인
- **Keychain Services** - 안전한 토큰 및 사용자 정보 저장
- **App Storage** - 사용자 설정 및 상태 관리

### Network & API
- **URLSession** - 비동기 REST API 통신 (요청 20초 / 리소스 60초 타임아웃)
- **JSON Codable** - 타입 안전한 데이터 직렬화/역직렬화
- **카카오 로컬 API** - 정확한 장소 검색 및 정보 제공
- **선별적 재시도** - 408·429·503·네트워크 단절만 재시도. 서버 오류(500·502·504)와
  클라이언트 오류는 다시 걸어도 같은 답이라 즉시 중단
- **통합 경로 조회** - `GET /routes` 한 번으로 요약·안내·경로선·장소를 모두 받는다

### Advanced Features
- **Background Task Management** - 백그라운드에서의 위치 추적
- **Memory Management** - 효율적인 리소스 관리 및 메모리 누수 방지
- **State Recovery** - 앱 종료 후 상태 복구
- **Real-time Updates** - 실시간 데이터 동기화

## 📱 앱 구조

```
Tourding_FE/
├── App/                           # 앱 진입점 및 의존성 주입
│   ├── Tourding_FEApp.swift     # 메인 앱 진입점
│   └── DependencyProvider.swift  # 의존성 주입 관리
├── Views/                         # SwiftUI 뷰 컴포넌트
│   ├── Home/                     # 홈 화면
│   ├── Riding/                   # 라이딩 화면 (NMap/, BottomSheet/, DnD)
│   ├── RecommendRoute/           # 추천 코스 화면
│   ├── SpotSearch/              # 스팟 검색 및 필터링
│   ├── SpotAdd/                 # 스팟 추가 (라이딩 중)
│   ├── Detail/                  # 상세 정보 및 바텀시트
│   ├── Login/                   # 로그인 및 온보딩
│   ├── MyPage/                  # 마이페이지
│   └── Components/               # 재사용 가능한 컴포넌트
├── ViewModels/                   # MVVM 뷰모델
│   ├── Riding/                  # 라이딩 관련 뷰모델 (extension 분리)
│   │   ├── RidingViewModel.swift
│   │   ├── RidingViewModel+API.swift
│   │   ├── RidingViewModel+RouteReorder.swift   # 경유지 DnD
│   │   ├── RidingViewModel+Lifecycle.swift     # appear, 라이딩 시작/종료, 위치 추적
│   │   ├── RidingViewModel+LocationTracking.swift
│   │   ├── RidingViewModel+Utils.swift
│   │   └── NMap/                               # 지도 매니저 연동
│   ├── RecommendRoute/          # 추천 코스 뷰모델
│   ├── SpotSearch/              # 스팟 검색 뷰모델
│   └── Components/              # 공통 컴포넌트 뷰모델
├── Model/                       # 데이터 모델
│   ├── Riding/                  # 라이딩 관련 모델
│   ├── RecommendRoute/         # 추천 코스 모델 
│   ├── Search/                  # 검색 관련 모델
│   └── User/                    # 사용자 관련 모델
├── Network/                     # 네트워크 레이어
│   ├── NetworkService.swift    # 통합 네트워크 서비스
│   ├── KakaoLocalService.swift # 카카오 로컬 API
│   └── NetworkMonitor.swift    # 네트워크 상태 모니터링
├── Repository/                  # 데이터 저장소 (protocol + DI)
│   ├── protocol/               # Repository 프로토콜
│   ├── Mock/                   # MockRouteRepository, MockKakaoRepository
│   ├── RouteRepository.swift   # 경로 데이터 관리
│   ├── TourRepository.swift    # 투어 데이터 관리
│   ├── UserRepository.swift      # 사용자 데이터 관리
│   └── KakaoRepository.swift   # 카카오 API 연동
├── Extension/                   # Color+Hex, Font+CustomFont 등
├── Utils/                       # 유틸리티
│   ├── SafeAreaUtils.swift
│   ├── FixtureLoader.swift       # Mock fixture 로더
│   └── MockAPIConfiguration.swift
└── Resources/                   # 리소스 파일
    ├── Assets.xcassets/        # 이미지 및 색상 리소스
    ├── Fixtures/               # 서버 응답 캡처 JSON (Mock API용)
    ├── Font/                   # 커스텀 폰트 (Pretendard)
    └── GIF/                    # 애니메이션 리소스

Tourding_FETests/                 # Swift Testing (FixtureLoaderTests 등)
```

## 🚀 시작하기

### 요구사항
- **iOS 17.0+** (최신 기능 활용)
- **Xcode 15.0+** (SwiftUI 최적화)
- **Swift 5.9+** (최신 언어 기능)
- **macOS 14.0+** (개발 환경)

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

### 🏠 홈 화면
- **지도 기반 메인 화면**: 현재 위치 중심의 인터랙티브 지도
- **코스 생성 시작점**: 출발지/도착지 설정 및 경로 계획
- **빠른 액세스**: 자주 사용하는 기능들에 대한 바로가기

### 🚴‍♂️ 라이딩 화면 (핵심 기능)
- **편집 / 라이딩 모드**: 코스 편집(`flag=false`)과 실시간 네비게이션(`flag=true`) 분리
- **경유지 드래그 앤 드롭**: 순서 변경 시 지도 마커·경로선 즉시 동기화
- **실시간 네비게이션**: GPS 기반 정확한 길 안내
- **나침반 모드**: 사용자 방향에 따른 카메라 자동 회전 (진북 기준)
- **지도 탐색**: 지도를 밀면 카메라 추적이 풀려 경로를 자유롭게 살펴볼 수 있고,
  3m 이상 이동하거나 `경로 안내 재개` 버튼을 누르면 다시 따라옵니다
- **마커 자동 관리**: 지나간 경로 마커 자동 제거 (30m 임계값)
- **편의시설 토글**: 화장실, 편의점 등 주변 시설 실시간 표시
- **동적 카메라**: 바텀시트 높이에 따른 카메라 시점 자동 조정
- **라이딩 중 스팟 추가**: 새로운 장소를 경로에 즉시 추가

### 🎯 추천 코스 화면
- **테마별 분류**: 자연, 문화, 맛집, 힐링 등 다양한 카테고리
- **상세 정보**: 난이도, 소요시간, 주요 포인트 정보 제공
- **원클릭 적용**: 추천 코스를 바로 내 코스로 적용

### 🔍 스팟 검색 화면
- **카카오 로컬 API**: 정확한 장소 검색 및 정보 제공
- **실시간 필터링**: 카테고리별, 거리별 스팟 필터링
- **최근 검색 기록**: 자주 찾는 장소 빠른 재검색
- **지도 연동**: 검색 결과를 지도에서 바로 확인

### 📍 상세 정보 화면
- **바텀시트 UI**: 직관적인 정보 표시
- **이미지 줌**: 스팟 이미지 확대/축소 기능
- **상세 정보**: 주소, 전화번호, 운영시간 등 완전한 정보
- **즉시 추가**: 상세 정보에서 바로 경로에 추가

### 👤 마이페이지
- **사용자 정보**: 프로필 및 설정 관리
- **서비스 정보**: 앱 정보 및 고객 지원
- **로그아웃**: 안전한 계정 관리

## 🔧 개발 환경 설정

### 필요한 API 키
1. **네이버 지도 API**
   - [네이버 클라우드 플랫폼](https://www.ncloud.com/)에서 발급
   
2. **카카오 로그인 API**
   - [카카오 개발자 콘솔](https://developers.kakao.com/)에서 발급

### 환경 변수 설정
`Config.xcconfig` 파일에 API 키들을 설정하세요:

```xcconfig
# 네이버 지도 API
NAVER_APP_KEY = your_naver_app_key

# 카카오 로그인 API
KAKAO_NATIVE_APP_KEY = your_kakao_native_key
KAKAO_REST_API_KEY = your_kakao_rest_key

# 백엔드 서버 URL
BASE_URL = your_backend_url

# 카카오 로컬 API URL (선택사항)
KAKAO_URL = https://dapi.kakao.com
```

### 주요 설정 사항
- **위치 권한**: `Info.plist`에서 위치 사용 권한 설명 설정
- **네트워크 보안**: HTTPS 통신을 위한 보안 설정
- **백그라운드 모드**: 위치 추적을 위한 백그라운드 실행 허용

### Mock API (개발·테스트)

백엔드 없이 라이딩 흐름을 검증할 수 있습니다.

- **활성화**: Xcode Launch Argument `-UseMockAPI` 또는 DEBUG에서 `MockAPIConfiguration.enableMockAPI()`
- **Fixture**: `Resources/Fixtures/` — 경로, 가이드, 편의시설 등 서버 응답 JSON
- **시나리오**: `MockRouteRepository` — `.withWaypoints`(기본), `.simple`(출발·도착만)

### 아키텍처 (Riding 모듈)

```
View → ViewModel → Repository(protocol)
                      ├─ RouteRepository → NetworkService
                      └─ MockRouteRepository → FixtureLoader (DEBUG)
```

`RidingViewModel`은 extension으로 역할을 분리합니다.

| Extension | 역할 |
|-----------|------|
| `+API` | 서버/Mock API 호출 |
| `+RouteReorder` | 경유지 DnD, 지도 동기화 |
| `+Lifecycle` | appear, 라이딩 시작/종료, 포그라운드, 위치 콜백 |
| `+LocationTracking` | 3m 이동 감지 + 추적 자동 재개, 30m 마커 통과 |
| `+Utils` | 좌표 파싱, 포맷 |

### 경로 데이터 흐름

서버는 `POST /routes`·`GET /routes`·AI 경로 재설정 모두 같은 형태(`RouteGuideResponse`)로
요약·안내·경로선·장소를 한 번에 돌려줍니다. 앱은 이를 **하나의 반영 경로**로 처리합니다.

```
RouteGuideResponse
  ├─ applyRouteBundle()    요약 · 경유지 · 장소 기준 마커 · 경로선
  └─ applyGuideMarkers()   라이딩 중 안내 기준 마커 (백업 후 교체)
```

라이딩 시작은 `POST /routes` 응답을 그대로 재사용하므로 별도 조회를 하지 않습니다.

### 테스트

```bash
xcodebuild test -scheme Tourding_FE \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -only-testing:Tourding_FETests \
  -derivedDataPath /tmp/TourdingDD
```

현재 **220개 통과 / 스킵 0**. 기능 추가·버그 수정·리팩토링 모두 실패하는 테스트를 먼저
작성하는 TDD로 진행합니다.

자세한 개발 가이드는 [`CLAUDE.md`](CLAUDE.md)를 참고하세요.

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


