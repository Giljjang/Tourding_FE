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
| 개발 방식 | **TDD 필수** — `.claude/skills/tourding-tdd/` |
| 테스트 | Swift Testing — `Tourding_FETests` (호스팅 유닛테스트) |
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
├── ViewModels/Riding/      +API, +RouteReorder, +Lifecycle, +LocationTracking, +Utils, NMap/
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
| `routeSource` | `.draft` / `.recentUsed` — `isUsed` 판정의 **단일 소스**. `handleInitialEntry`에서 1회 저장 |
| `routeLocation`, `pathCoordinates`, `guideList` | 지도·가이드 데이터 |
| `markerCoordinates`, `markerIcons` | `applyRouteLocationMarkers(from:)`로 갱신 |
| `userSession` | `UserSessionProviding` — `userId` 공급자. ViewModel에서 `KeychainHelper` 직접 호출 금지 |
| `reorderPersistTask` | 경유지 DnD 디바운스 POST Task |
| `toiletMarkerTask` / `convenienceStoreMarkerTask` | 편의시설 마커 갱신 Task. 새 요청·토글 OFF·`endRiding`에서 취소 |
| `isUsed` (API) | 서버 경로 사용 여부 |

### ViewModel extensions

| 파일 | 역할 |
|------|------|
| `+API.swift` | 서버/Mock 호출, `postRouteDragNDropAPI` |
| `+RouteReorder.swift` | 경유지 DnD — 지도 동기화, 디바운스 POST, `persistRouteOrderAfterReorder` |
| `+LocationTracking.swift` | 3m 이동, 30m 마커 통과 |
| `+Utils.swift` | 좌표 파싱, 포맷 |
| `+Lifecycle.swift` | appear, riding start/end, foreground, location tracking |

### RidingView 라이프사이클 (`+Lifecycle`)

```
RidingView.onAppear
  → configureLocationManager
  → handleOnAppear → loadEditModeRouteData (편집 모드 API 3종)
  → onStartRiding → startRidingWithLoading → startRidingAPIProcess

RidingView.onChange(flag == true)
  → activateRidingLocationTracking → setupRidingLocationCallback (단일 콜백)

위치 콜백 (setupRidingLocationCallback)
  → mapViewController.updateUserLocation
  → updateUserLocationAndCheckMarkers (+LocationTracking)
```

**View 책임** (~423줄): UI, 바텀시트 카메라 피봇, 위치 권한 모달, ViewModel 메서드 위임  
**ViewModel 책임** (`+Lifecycle`): API 오케스트레이션, 라이딩 시작/종료, 포그라운드 새로고침, 위치 콜백 단일 설정

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

### 지도 참조 소유권 (중요)

`RidingViewModel`의 지도 관련 프로퍼티는 **전부 `weak`**다.
소유자는 화면(`MapViewController` / `RidingView`의 `@StateObject`)이고 ViewModel은 앱 수명이므로,
strong으로 잡으면 화면을 떠난 뒤에도 `MapViewController`와 그 `CLLocationManager`가 살아 GPS가 계속 돈다.
`MapViewController.ridingViewModel`도 같은 이유로 `weak`.

**새 지도 참조를 추가할 때도 `weak`을 유지할 것.** 회귀 방지 테스트: `MapBindingLifetimeTests`

### 미해결 이슈

1. **LocationManager 이중 인스턴스** — `RidingView` `@StateObject locationManager` vs `MapViewController.locationManager`
2. **바텀시트 카메라 피봇** — `RidingView.onChange(currentPosition)` 로직 ViewModel 이전 검토
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

## 개발 방식 — TDD (필수)

**실패하는 테스트 없이는 프로덕션 코드를 쓰지 않는다.** 기능 추가·버그 수정·리팩토링 모두 해당한다.
특히 Riding AI 기능(코스 요약, 경유지 추천, 자연어 안내)은 예외 없이 이 방식으로 개발한다.

구현을 먼저 썼다면 지우고 다시 시작한다. "참고용으로 남긴다"는 위반이다.

**RED는 어서션 실패다. 컴파일 에러는 RED가 아니다.**
Swift에서는 타입이 없으면 테스트가 컴파일되지 않으므로, 시그니처만 있는 껍데기를 만들어 컴파일을 통과시킨 뒤
**어서션이 실패하는 것을 눈으로 확인**한다. 껍데기 본문은 **중립 기본값**(빈 배열/`nil`/기본 구조체)을 반환해야 한다 —
`fatalError`는 러너 프로세스를 죽여 크래시가 되므로 RED가 성립하지 않는다. 껍데기 본문에 동작을 넣으면 위반이다.

**검증된 테스트 명령** (세 인자 모두 필수):

```bash
xcodebuild test -scheme Tourding_FE \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -only-testing:Tourding_FETests \
  -derivedDataPath /tmp/TourdingDD
```

- `OS=18.5` 없으면 destination을 못 찾는다 (테스트 타겟 deployment target 18.5)
- `-only-testing` 없으면 UI 테스트까지 돈다
- `-derivedDataPath` 없으면 Xcode 실행 중에 `build.db: database is locked`
- 사이클 비용: 콜드 3분 29초 / 웜 2분 01초 — 느리다는 것이 테스트를 몰아 쓰는 근거가 되지는 않는다

**새 테스트 파일**은 `Tourding_FETests/`에 만들기만 하면 타겟에 자동 편입된다
(`objectVersion = 77` + `PBXFileSystemSynchronizedRootGroup`). **pbxproj를 편집하지 마라.**

**테스트하지 않는 것**: SwiftUI `body`, `URLSession` 실제 통신, NMFMapView 렌더링, 실제 GPS 시퀀스.
그 외는 전부 테스트한다. "LLM은 비결정적이라 못 한다"는 **응답 본문에만** 해당하며,
프롬프트 조립·파싱·상태 전이·폴백·취소는 전부 결정적이다.

상세 워크플로·합리화 대응표·Swift Testing 레시피: **`.claude/skills/tourding-tdd/`**

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
- [x] **P0 7건 수정 (TDD)** — 테스트 24개 통과
  - DI 그래프 앱 수명 고정 (`AppContainer` — 공유 ViewModel만)
  - 지도 참조 weak 전환 (순환 참조·GPS 잔존 해소)
  - 위치 콜백 클로저 `[weak userLocationManager]`
  - `DebugSessionLogger` 릴리즈 no-op (`#if DEBUG`)
  - `isLoading` `defer` 통일 (Riding 3곳 + Detail 2곳)
  - 디바운스 DnD Task self-cancel 해소
  - `routeSource` 상태 승격 — DnD·삭제·경로선 재조회·포그라운드

- [x] **AI 선행 리팩토링 3건 (TDD)** — 테스트 45개 통과
  - `UserSessionProviding` 주입 (`RidingViewModel`, `SpotAddViewModel`)
  - 편의시설 마커 `Task` 프로퍼티 노출 + `apply*()` 분리 + 취소 배선
  - `markerKinds(for:) -> [RouteMarkerKind]` 순수 함수 분리

### 다음
- [ ] `PathSimplifier` + `PathSimplificationMetrics` + perf A/B 로깅
- [ ] RidingViewModel Mock 시나리오 테스트 확대
- [ ] LocationManager 이중 인스턴스 정리 (`MapViewController.locationManager` vs `userLocationManager`)

### 기술 부채
- `POST /routes` 응답 타입 불일치 (`RoutesModel` vs `EmptyResponse`)
- UserRepository → NetworkService 통합
- ErrorType 이중화 해소
- `print` → OSLog

---

## AI 에이전트 규칙

**DO**: 실패하는 테스트 먼저, minimal diff, protocol DI, NMaps와 pure logic 분리, `@MainActor` UI 업데이트, 한국어 응답

**DON'T**: 테스트 없이 프로덕션 코드 작성, 컴파일 에러를 RED로 간주, `project.pbxproj` 편집, View에 오케스트레이션 추가, `RouteRepository.shared` 직접 참조로 Mock 우회, git commit/push (명시 요청 시만), 시크릿 커밋 (LLM API 키를 `Config.xcconfig`/Info.plist에 넣지 마라 — 앱 바이너리에 실린다), 경유지 DnD POST 후 `getRouteLocationAPI` 호출 (순서 덮어씀)

**새 fixture 추가 시**: JSON 파일 + `FixtureLoaderTests` 디코딩 검증

---

## Cursor Rules

| 파일 | scope |
|------|-------|
| `tourding-core.mdc` | alwaysApply |
| `tdd-workflow.mdc` | alwaysApply |
| `swift-style.mdc` | `**/*.swift` |
| `network-repository.mdc` | Network, Repository, Utils |
| `riding-map.mdc` | Riding, NMap |
| `testing-improvements.mdc` | Tests |
