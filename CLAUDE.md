# Tourding_FE — AI Agent Guide

SwiftUI + NMapsMap 자전거 라이딩/관광 iOS 앱.

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 아키텍처 | MVVM + Repository (protocol DI) |
| 지도 | NMapsMap |
| DI | `DependencyProvider` |
| 네비게이션 | `NavigationManager` + `ViewType` stack |
| 인증 | Kakao SDK + Keychain (`KeychainHelper.loadUid()`) |
| 테스트 | Swift Testing — `FixtureLoaderTests` |
| Mock | `MockRouteRepository`, `MockKakaoRepository` + `Resources/Fixtures/` |

---

## 폴더 구조

```
Tourding_FE/
├── App/                    Tourding_FEApp, DependencyProvider
├── Network/                NetworkService, AppConfig, KakaoLocalService
├── Repository/
│   ├── protocol/
│   ├── Mock/               MockRouteRepository, MockKakaoRepository
│   └── *Repository.swift
├── Model/                  Riding, Search, Detail, User…
├── ViewModels/Riding/      +API, +LocationTracking, +Utils, NMap/
├── Views/Riding/           RidingView, NMap/, BottomSheet/
├── Extension/              Color+Hex, Font+CustomFont
├── Utils/                  FixtureLoader, MockAPIConfiguration, SafeAreaUtils
└── Resources/Fixtures/     서버 캡처 JSON
```

---

## 아키텍처

```
View → ViewModel → Repository(protocol)
                      ├─ RouteRepository → NetworkService
                      └─ MockRouteRepository → FixtureLoader (DEBUG)
```

```swift
// DependencyProvider — DEBUG에서 Mock 자동 전환
private static func makeRouteRepository() -> RouteRepositoryProtocol {
    #if DEBUG
    if MockAPIConfiguration.useMockAPI { return MockRouteRepository.shared }
    #endif
    return RouteRepository.shared
}
```

**Mock 활성화**: Launch Argument `-UseMockAPI` 또는 `MockAPIConfiguration.enableMockAPI()`

**Mock 시나리오** (`MockRouteRepository`):
- `.withWaypoints` (기본): Start + WayPoint + Goal
- `.simple`: Start + Goal — `POST /routes`에서 `wayPoints`가 비어 있을 때

---

## Riding 모듈

### ViewModel 상태

| 프로퍼티 | 의미 |
|----------|------|
| `flag` | `false` 편집 / `true` 라이딩 중 |
| `routeLocation`, `pathCoordinates`, `guideList` | 지도·가이드 데이터 |
| `isUsed` (API) | 서버 경로 사용 여부 |

### 지도 브릿지

```
NMapView → MapViewRepresentable → MapViewController
  → PathManager (Douglas-Peucker), MarkerManager
```

`MapViewRepresentable.updateUIView`에서 ViewModel에 `pathManager` 포함 전체 매니저 연결.

### 미해결 이슈

1. **RidingView ~737줄** — API/위치/카메라 로직 → `RidingViewModel+Lifecycle` 이전 예정
2. **LocationManager 콜백 중복** — onAppear, onChange(flag), startRidingAPIProcess
3. **POST /routes** — 서버는 `RoutesModel` 반환, 앱은 `EmptyResponse`로 무시

---

## API 요약

**Request**: `RequestRouteModel` — 좌표는 `경도,위도` 순 (`wayPoints`: `lon,lat|lon,lat`)

**Response**: `RoutePathModel`, `LocationNameModel`(Start/WayPoint/Goal), `GuideModel`, `RoutesModel`, `FacilityInfoModel`

**Fixtures** (`Resources/Fixtures/`):

| 파일 | 용도 |
|------|------|
| `routes_location_name_simple.json` | 2스팟 |
| `routes_location_name_with_waypoints.json` | 3스팟 |
| `routes_guide_simple.json` / `_with_waypoints.json` | 가이드 (type 9 = 경유지) |
| `routes_path_unused.json` | 258좌표 (PathManager 벤치마크) |
| `routes_toilet.json`, `routes_convenience_store.json` | 편의시설 |

---

## 코드 스타일

- ViewModel: `final class`, API 메서드 `*API` 접미사, extension 분리
- View: init injection + `@StateObject`, `private var` 서브뷰
- MARK: `// MARK: -` (신규 코드)
- 디자인: `.pretendard*`, `Color.gray1~6`, `Color.main`
- 로깅: 현재 `print` + 이모지 → 예정 `AppLogger` (OSLog)

---

## 개선 로드맵

### 완료
- [x] 네이밍 오타 정리 (`Extension`, `HomeView`, `isNotNormal`)
- [x] `pathManager` ViewModel 연결
- [x] Fixture JSON + MockRepository + DI + 기본 테스트

### 다음
- [ ] `PathSimplifier` + `PathSimplificationMetrics` + perf A/B 로깅
- [ ] RidingViewModel Mock 시나리오 테스트 확대
- [ ] `RidingViewModel+Lifecycle` — View 로직 이전
- [ ] LocationManager 소유권·콜백 단일화

### 기술 부채
- UserRepository → NetworkService 통합
- ErrorType 이중화 해소
- `print` → OSLog

---

## AI 에이전트 규칙

**DO**: minimal diff, protocol DI, NMaps와 pure logic 분리, `@MainActor` UI 업데이트, 한국어 응답

**DON'T**: View에 오케스트레이션 추가, `RouteRepository.shared` 직접 참조로 Mock 우회, git commit/push (명시 요청 시만), 시크릿 커밋

**새 fixture 추가 시**: JSON 파일 + `FixtureLoaderTests` 디코딩 검증

---

## Cursor Rules

| 파일 | scope |
|------|-------|
| `tourding-core.mdc` | alwaysApply |
| `swift-style.mdc` | `**/*.swift` |
| `network-repository.mdc` | Network, Repository, Utils |
| `riding-map.mdc` | Riding, NMap |
| `testing-improvements.mdc` | Tests |
