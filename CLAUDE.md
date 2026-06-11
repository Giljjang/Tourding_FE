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
├── ViewModels/Riding/      +API, +RouteReorder, +LocationTracking, +Utils, NMap/
├── Views/Riding/           RidingView, NMap/, BottomSheet/, RouteLocationDropDelegate
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
| `markerCoordinates`, `markerIcons` | `applyRouteLocationMarkers(from:)`로 갱신 |
| `reorderPersistTask` | 경유지 DnD 디바운스 POST Task |
| `isUsed` (API) | 서버 경로 사용 여부 |

### ViewModel extensions

| 파일 | 역할 |
|------|------|
| `+API.swift` | 서버/Mock 호출, `postRouteDragNDropAPI` |
| `+RouteReorder.swift` | 경유지 DnD — 지도 동기화, 디바운스 POST, `persistRouteOrderAfterReorder` |
| `+LocationTracking.swift` | 3m 이동, 30m 마커 통과 |
| `+Utils.swift` | 좌표 파싱, 포맷 |
| `+Lifecycle.swift` | appear, riding start/end, foreground, location tracking |

### 경유지 드래그앤드롭 (`flag=false` 편집 모드)

```
SheetContentView.onDrag/onDrop
  → RouteLocationDropDelegate
    → dropEntered: routeLocation 재할당 + syncMapAfterRouteReorder + schedulePersist (0.4s)
    → performDrop: persistRouteOrderAfterReorder (즉시 POST)
  → RidingViewModel+RouteReorder
    → postRouteDragNDropAPI → getRoutePathAPI → syncMapAfterRouteReorder
```

**주의 (ScrollView DnD 특성)**:
- `performDrop`이 호출되지 않는 경우가 있음 → `dropEntered` + 디바운스 POST로 보완
- `routeLocation.move()` in-place는 `@Published` 미트리거 → **배열 재할당** 필수
- POST 후 `getRouteLocationAPI` **호출하지 않음** (서버 `sequenceNum` 순으로 드래그 순서 덮어씀)
- 경유지 마커 번호: 배열 `index`가 아니라 WayPoint 순번(1, 2, 3…) — `makeMarkerIcons(for:)`

**디버그 로그**: `🛣️ [DragDrop]` — POST body JSON

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
- [x] 경유지 드래그앤드롭 — 지도 마커·경로 동기화 (`+RouteReorder`, `RouteLocationDropDelegate`)
- [x] 첫 로그인 추천 코스 표시 (`HomeViewModel.getRouteRecommendAPI` uid guard 제거)
- [x] `RidingViewModel+Lifecycle` — View 오케스트레이션 이전, 위치 콜백 단일화 (`setupRidingLocationCallback`)

### 다음
- [ ] `PathSimplifier` + `PathSimplificationMetrics` + perf A/B 로깅
- [ ] RidingViewModel Mock 시나리오 테스트 확대
- [ ] LocationManager 이중 인스턴스 정리 (`MapViewController.locationManager` vs `userLocationManager`)

### 기술 부채
- UserRepository → NetworkService 통합
- ErrorType 이중화 해소
- `print` → OSLog

---

## AI 에이전트 규칙

**DO**: minimal diff, protocol DI, NMaps와 pure logic 분리, `@MainActor` UI 업데이트, 한국어 응답

**DON'T**: View에 오케스트레이션 추가, `RouteRepository.shared` 직접 참조로 Mock 우회, git commit/push (명시 요청 시만), 시크릿 커밋, 경유지 DnD POST 후 `getRouteLocationAPI` 호출 (순서 덮어씀)

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
