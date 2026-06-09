# Tourding_FE — Claude / AI Agent Guide

SwiftUI + NMapsMap 자전거 라이딩/관광 경로 iOS 앱. 이 문서는 AI 에이전트가 코드베이스를 이해하고 일관되게 수정하기 위한 가이드입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 언어 | Swift 5+, SwiftUI |
| 지도 | NMapsMap (Naver Map SDK) |
| 아키텍처 | MVVM + Repository |
| DI | `DependencyProvider` |
| 네비게이션 | `NavigationManager` + `ViewType` enum stack |
| 인증 | Kakao SDK + Keychain (`KeychainHelper.loadUid()`) |
| 테스트 | Swift Testing (`Tourding_FETests`) — 현재 거의 비어 있음 |

---

## 2. 폴더 구조

```
Tourding_FE/
├── App/
│   ├── Tourding_FEApp.swift      # @main, Splash → Login/Tab, DI 조립
│   └── DependencyProvider.swift  # ViewModel factory
├── Network/
│   ├── NetworkService.swift      # 공통 HTTP (async/await)
│   ├── AppConfig.swift           # BASE_URL (Info.plist)
│   ├── KakaoLocalService.swift   # Kakao REST API
│   └── NetworkMonitor.swift      # NWPathMonitor
├── Repository/
│   ├── protocol/                 # *RepositoryProtocol
│   ├── RouteRepository.swift
│   ├── TourRepository.swift
│   ├── KakaoRepository.swift
│   └── UserRepository.swift      # ⚠️ NetworkService 미사용
├── Model/
│   ├── Riding/Request|Response/
│   ├── Search/, Detail/, User/, Home/
│   └── APIResponse.swift         # EmptyResponse
├── ViewModels/
│   ├── Riding/                   # 가장 복잡 — +API, +LocationTracking, +Utils
│   │   └── NMap/                 # PathManager, LocationManager, MarkerManager
│   ├── Home/, SpotSearch/, RecommendRoute/, Login/, Tab/, Components/
├── Views/
│   ├── Riding/                   # RidingView(737줄), NMap/, BottomSheet/
│   ├── RecommendRoute/           # PathManager 재사용
│   ├── Components/               # 재사용 UI (CustomModalView, FilterView…)
│   └── …기능별 View
├── Extension/                    # Color+Hex, Font+CustomFont, UIColor+Hex
│   ├── Color+Hex.swift           # 디자인 시스템 색상
│   ├── Font+CustomFont.swift     # Pretendard
│   └── UIColor+Hex.swift
├── Utils/
│   └── SafeAreaUtils.swift
└── Resources/                    # Assets, GIF
Tourding_FETests/
Tourding_FEUITests/
.cursor/rules/                    # Cursor AI 규칙 (.mdc)
```

---

## 3. 아키텍처

```
View ──→ ViewModel ──→ Repository (protocol) ──→ NetworkService ──→ URLSession
         @Published              ↑
                                 MockRepository (구현 예정)
```

### DI 패턴

```swift
// DependencyProvider.swift
@MainActor static func makeRidingViewModel() -> RidingViewModel {
    RidingViewModel(
        routeRepository: RouteRepository.shared,
        kakaoRepository: KakaoRepository.shared
    )
}

// View — init injection + @StateObject
init(viewModel: HomeViewModel) {
    self._viewModel = StateObject(wrappedValue: viewModel)
}
```

### 전역 EnvironmentObject

- `NavigationManager` — push/pop, `ViewType` stack
- `ModalManager` — `CustomModalView` 표시
- `RouteSharedManager` — 홈↔라이딩 경로 공유
- `LoginViewModel` — 로그인 상태

---

## 4. 코드 스타일

### 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| ViewModel | `XxxViewModel` | `RidingViewModel` |
| View | `XxxView` | `RidingView` |
| Repository | `XxxRepository` + Protocol | `RouteRepositoryProtocol` |
| API 메서드 | `*API` 접미사 | `getRoutePathAPI()` |
| Model Request | `Request*` 또는 `Req*` | `RequestRouteModel`, `ReqFacilityInfoModel` |
| Model Response | 도메인+Model | `RoutePathModel`, `GuideModel` |
| Component | `*Component` 또는 `Custom*` | `LocalSpotRowItemComponent` |

### Swift 관례

- ViewModel: `final class`, `@MainActor` on async UI methods
- Model: `struct`, `Codable`
- MARK: `// MARK: - 섹션명` (기존 `//MARK:` 혼재 — 신규는 공백 포함)
- View 서브컴포넌트: `private var header: some View`
- 일부 View 종료 주석: `// : VStack` (기존 스타일 유지)

### 디자인 시스템

```swift
.font(.pretendardSemiBold(size: 16))
.foregroundColor(.gray5)        // gray1(밝음) ~ gray6(어두움)
.background(Color.main)          // #00E1FF
.cornerRadius(10)
```

색상 정의: `Extension/Color+Hex.swift`

### 로깅 (현재)

```swift
print("🔵 요청 시작")
print("❌ 에러: \(error)")
print("📍 위치: \(lat), \(lng)")
print("🛣️ 경로 최적화: \(count)개")
```

**개선 방향**: `AppLogger` (OSLog) + category별 레벨. verbose location log는 DEBUG only.

---

## 5. Riding 모듈 (핵심)

### 상태 (`RidingViewModel`)

| 프로퍼티 | 의미 |
|----------|------|
| `flag: Bool` | `false` 편집 모드 / `true` 라이딩 중 |
| `routeLocation`, `routeMapPaths`, `routeTotal` | 라이딩 전 |
| `guideList` | 라이딩 중 turn-by-turn |
| `pathCoordinates`, `markerCoordinates/Icons` | 지도 바인딩 |
| `isUsed` (API) | 서버 경로 사용 여부 — flag와 연동 |

### 지도 브릿지

```
NMapView (SwiftUI)
  → MapViewRepresentable (UIViewRepresentable)
    → MapViewController (UIViewController)
      → PathManager, MarkerManager, NMFNaverMapView
```

### PathManager — Douglas-Peucker

- `setCoordinates()` → simplify → draw 이중 NMFPath
- tolerance `0.00001` (~1m)
- **분리 예정**: `PathSimplifier` (pure, testable) + `PathSimplificationMetrics`

### 알려진 이슈

1. **`RidingViewModel.pathManager` 미연결** — `MapViewRepresentable.updateUIView`에서 `markerManager`/`mapViewController`는 연결하지만 `pathManager`는 누락. `RecommendMapViewRepresentable` 참고.
2. **RidingView 737줄** — API/위치/카메라 오케스트레이션이 View에 있음 → `RidingViewModel+Lifecycle`으로 이전 예정.
3. **LocationManager 콜백 중복** — onAppear, onChange(flag), startRidingAPIProcess에서 각각 설정.
4. **LocationManager 소유** — View `@StateObject` + ViewModel `userLocationManager` 이중 참조.

---

## 6. Network / API

### NetworkService 사용법

```swift
let paths: [RoutePathModel] = try await NetworkService.request(
    apiType: .main,
    endpoint: "/routes/path",
    parameters: ["userId": String(userId), "isUsed": String(isUsed)]
)
```

### Riding API 모델

**Request**: `RequestRouteModel` (userId, start, goal, wayPoints, locateName, typeCode, contentId, contentTypeId, isUsed)

**Response**:
- `RoutePathModel` — sequenceNum, lon, lat
- `LocationNameModel` — name, type(Start/Goal/WayPoint), lon, lat
- `GuideModel` — instructions, type(int→GuideType), guideText computed
- `RoutesModel` — duration(초), distance(m)
- `FacilityInfoModel` — 화장실/편의점

---

## 7. 테스트 & Mock (구현 예정)

### 목표 구조

```
Resources/Fixtures/           # 서버 JSON 캡처
Repository/Mock/              # MockRouteRepository, MockKakaoRepository
Utils/AppLogger.swift
Services/PathSimplifier.swift
```

### 테스트 우선순위

1. PathSimplifier (단위)
2. Haversine / 마커 통과 로직
3. RidingViewModel + MockRepository (통합)
4. pathManager 연결 후 refreshMapDisplay regression

### DependencyProvider mock 분기 (예정)

```swift
#if DEBUG
static func makeRidingViewModel(useMock: Bool = false) -> RidingViewModel { ... }
#endif
```

---

## 8. 개선 로드맵

### Phase 1 — 기반
- [ ] 서버 응답 JSON fixture 저장
- [ ] MockRouteRepository / MockKakaoRepository
- [ ] DependencyProvider DEBUG mock 분기
- [ ] MapViewRepresentable pathManager 연결

### Phase 2 — 측정 가능한 최적화
- [ ] PathSimplifier + PathSimplificationMetrics 추출
- [ ] AppLogger + raw/simplified A/B perf 모드
- [ ] fixture 기준 벤치마크 수치 문서화

### Phase 3 — 테스트
- [ ] PathSimplifier 단위 테스트
- [ ] RidingViewModel Mock 시나리오 테스트

### Phase 4 — MVVM 정리
- [ ] RidingViewModel+Lifecycle (appear, start/end riding, foreground)
- [ ] LocationManager 소유권·콜백 단일화
- [ ] RidingView 150~250줄 목표

### 기타 기술 부채
- UserRepository → NetworkService 통합
- ErrorType 이중화 해소
- `print` → OSLog 정리

---

## 9. AI 에이전트 작업 규칙

### DO
- 요청 범위만 수정 (minimal diff)
- 주변 파일 스타일·네이밍·패턴 따르기
- Repository는 protocol 타입으로 주입
- NMaps 의존 로직과 pure logic 분리
- `@MainActor` UI 업데이트 준수
- 사용자에게 한국어로 응답

### DON'T
- View에 API/위치 오케스트레이션 추가
- singleton 직접 참조로 Mock 경로 막기
- print 남발 (Logger 도입 후)
- git commit/push — 사용자 명시 요청 시에만
- .env, API key 등 시크릿 커밋

### RidingView 수정 시
- UI 레이아웃 변경 vs 로직 이전 구분
- 로직 이전은 `RidingViewModel+Lifecycle.swift` 신규 extension 우선
- LocationManager 콜백은 **한 곳**에서만 설정

### PathManager 수정 시
- Douglas-Peucker는 `PathSimplifier`로 분리 후 PathManager는 thin wrapper
- perf 로그는 `PathSimplificationMetrics` struct로 반환

---

## 10. Cursor Rules

`.cursor/rules/`에 세분화된 규칙 파일:

| 파일 | scope |
|------|-------|
| `tourding-core.mdc` | alwaysApply — 프로젝트 개요 |
| `swift-style.mdc` | `**/*.swift` — 코딩 스타일 |
| `network-repository.mdc` | Network/Repository |
| `riding-map.mdc` | Riding/NMap |
| `testing-improvements.mdc` | Tests + 로드맵 |

이 CLAUDE.md와 `.cursor/rules/`는 함께 참조하세요.
