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
| 인증 | Kakao SDK + Keychain. `userId`는 `UserSessionProviding` 주입, 세션 정리는 `KeychainHelper.clearSession()` 한 곳 |
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
| `routeSource` | `.draft` / `.recentUsed` — 화면이 진입한 경로 출처. `handleInitialEntry`에서 1회 저장 |
| `isUsedRoute` | **`flag \|\| routeSource.isUsed`** — 서버의 어느 경로를 읽고 쓸지 판정하는 단일 소스. 모든 `get*API` 기본값이 이 값을 쓴다. `flag`(라이딩 중인가)만으로 판정하면 최근 경로 편집 시 draft를 읽는다 |
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

`RecommendRouteViewModel` ↔ `RecommendMapViewController`도 같다.
이쪽은 ViewModel이 **화면 수명**(`@StateObject`)이라 순환이 나면 화면에 들어갈 때마다
한 세트씩 쌓인다 — 앱 수명인 라이딩 쪽(1세트 잔존)보다 나쁘다.

**새 지도 참조를 추가할 때도 `weak`을 유지할 것.**
회귀 방지 테스트: `MapBindingLifetimeTests`, `RecommendMapBindingLifetimeTests`

### 마커 통과 판정 (A)

임계값(30m) 안에 마커가 있으면 **맨 앞 한 칸만** 소비한다.
이전에는 "가장 가까운" 마커를 찾아 `0...그 인덱스`를 한꺼번에 지워서,
30m 안에 마커가 둘 이상이거나 GPS가 튀면 중간 안내가 화면에 한 번도 뜨지 않고 사라졌다
(실제 fixture에 20.7m·21.2m 간격 구간이 있다).

여러 칸 밀리면 다음 위치 갱신들로 따라잡는다 — 콜백이 3m 이동마다 오므로 두 칸이면 약 6m 주행이다.
회귀 방지 테스트: `MarkerPassingTests`

### 미해결 이슈

1. **LocationManager 이중 인스턴스** — `RidingView` `@StateObject locationManager` vs `MapViewController.locationManager`
2. **바텀시트 카메라 피봇** — `RidingView.onChange(currentPosition)` 로직 ViewModel 이전 검토
3. **POST /routes** — 서버는 `RoutesModel` 반환, 앱은 `EmptyResponse`로 무시

---

## 네트워크 계약

**경로 조회는 `getRouteBundle` (`GET /routes`) 하나로 받는다.**
서버가 요약·`guides`·`paths`·`locations`를 한 응답에 담아준다(`RouteGuideRespDto`).
개별 엔드포인트를 각각 부르면 서버가 같은 경로를 여러 번 재계산한다 —
응답 하나가 80KB대이고, 실측상 짧은 세션에 `/routes` 200 응답만 12회 나간 뒤
`/routes`·`/routes/path`·`/routes/guide`가 연쇄 500을 반환했다.

**응답 모델의 새 필드는 옵셔널로 둔다.** 필드 하나 때문에 응답 전체가 폐기되는 실패를
두 번 겪었다(`/routes/guide` 형태 변경, 상세의 분류 필드 누락).

**재시도는 될 만한 것에만.** `ErrorType.isRetryable` —
408·429·503·네트워크 단절만 재시도하고 **500·502·504·4xx는 즉시 중단**한다.
이 서버의 500은 결정적이다(실측: `/routes/path` 500이 3회 연속 동일).
재시도 루프를 새로 만들면 이 가드를 반드시 넣을 것.

**상태 판정은 `HTTPStatusValidator.error(for:)`.** `(200..<300)` 범위로 본다.
"아는 에러 코드 목록" 조회 방식은 429·504를 통과시켜 `decodingFailure`로 둔갑시켰다.

**타임아웃**: `NetworkService.session` (요청 20초 / 리소스 60초). `URLSession.shared`를 쓰지 말 것.

**실패를 삼키지 마라.** `catch { print }` 후 화면을 그대로 진행시키면 사용자는 성공한 줄 안다.
오늘 이 형태로 4건이 나왔다 — 삭제 안 됨, 스팟 추가 안 됨, 상세 빈 화면,
그리고 **추천 코스 자리에 사용자의 옛 코스가 표시**됐다.
호출부가 분기해야 하면 성공 여부를 반환할 것.

---

## API 요약

**Request**: `RequestRouteModel` — 좌표는 `경도,위도` 순 (`wayPoints`: `lon,lat|lon,lat`)

**Response**: `RouteGuideResponse`(통합 — 요약·guides·paths·locations), `RoutePathModel`,
`LocationNameModel`(Start/WayPoint/Goal), `GuideModel`, `RoutesModel`(+ `routeSummaryId`·`ascent`·
`uphillLevel`·`appliedOption` 등 옵셔널), `RouteOptionModel`, `FacilityInfoModel`

`routeSummaryId`는 AI 경로 재설정(`/ai/routes/adjustments/*`)의 필수 입력이라 `routeTotal`에 보관한다.

**Fixtures** (`Resources/Fixtures/`):

| 파일 | 용도 |
|------|------|
| `routes_location_name_simple.json` | 2스팟 |
| `routes_location_name_with_waypoints.json` | 3스팟 |
| `routes_guide_simple.json` / `_with_waypoints.json` | 가이드 (type 9 = 경유지) |
| `routes_path_unused.json` | 258좌표 (PathManager 벤치마크) |
| `routes_toilet.json`, `routes_convenience_store.json` | 편의시설 |
| `routes_guide_response.json` | 변경된 서버 형태 (`RouteGuideRespDto` 객체) |
| `tour_area_detail_partial.json` | 분류 필드가 빠진 상세 응답 (부분 누락 내구성) |

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

- [x] **보안 3건 (TDD)** — 테스트 74개 통과
  - 로그아웃이 Keychain 세션을 남겨 자동 재로그인되던 문제 → `KeychainHelper.clearSession()` 단일 진입점
  - Keychain 저장에 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` 적용 (백업으로 타 기기 복원 차단)
  - `accessToken` 전문 콘솔 출력 제거
- [x] **지역 필터에서 충남·경남·전남이 검색되지 않던 문제 (TDD)** — `SearchRegion` 단일 소스
- [x] **최근 경로에서 경유지 삭제가 반영되지 않던 문제 (TDD)** — 테스트 62개 통과
  - 삭제 POST는 사용 완료 경로에, 직후 재조회는 draft를 읽어 목록이 원상복구되던 문제
  - `isUsedRoute = flag || routeSource.isUsed`로 판정 통일, 모든 `get*API` 기본값에 적용
  - 삭제+재조회를 `deleteWaypointAndRefresh`로 묶어 View에서 오케스트레이션 제거
- [x] **경로 추가 요청 데이터 버그 3건 (TDD)** — 테스트 56개 통과
  - `typeCode`만 `insert(at: count-1)`이라 새 스팟과 마지막 경유지의 카테고리가 뒤바뀌던 문제 (SpotAdd·Detail)
  - Detail이 `contentTypeId` 자리에 `contentId`를 보내던 복붙 오류
  - 좌표 규약(경도,위도)을 `RouteAddRequestTests`로 고정 + 모델 주석 정정
- [x] **AI 선행 리팩토링 3건 (TDD)** — 테스트 45개 통과
  - `UserSessionProviding` 주입 (`RidingViewModel`, `SpotAddViewModel`)
  - 편의시설 마커 `Task` 프로퍼티 노출 + `apply*()` 분리 + 취소 배선
  - `markerKinds(for:) -> [RouteMarkerKind]` 순수 함수 분리

- [x] **서버 API 변경 대응 + 라이딩 결함 (TDD)** — 테스트 130개, 스킵 0
  - **가이드 미표시** — `GET /routes/guide`가 배열 → `RouteGuideRespDto` 객체로 바뀌어
    `typeMismatch`로 실패. 재시도 3회가 전부 같은 이유로 실패해 `guideList`가 빈 채로 남았다
  - **라이딩 시작 Task 추적 불가** — 자식 Task라 취소할 수 없어, 종료 후 뒤늦게 끝난 가이드가
    편집 화면을 덮었다. `ridingStartTask`로 소유하고 `endRiding`에서 취소
  - **안내 건너뜀** — 30m 안에 마커가 둘 이상이면 중간 안내가 화면에 한 번도 안 뜨고 사라졌다.
    통과 판정 A(맨 앞 한 칸만 소비)로 변경
  - **스팟 추가 유실** — 경로 로드 전에 추가하면 guard에 걸려 POST가 안 나가고 화면만 넘어갔다
    (SpotAdd·Detail 두 진입점)
  - **추천 코스에 사용자 옛 코스 표시** — `/routes/by-name` 실패를 삼키고 화면을 넘겨,
    draft에 남아 있던 옛 코스를 추천 코스인 양 보여줬다
  - **추천 코스 화면 지도 순환 참조** — ViewModel ↔ MapViewController 양방향 strong.
    화면에 들어갈 때마다 GPS가 한 세트씩 쌓였다
  - **HTTP 2xx 판정·타임아웃·재시도 정책** — 429·504가 `decodingFailure`로 둔갑하던 문제,
    타임아웃 미설정(60초), 500에 3회 재시도하던 문제
  - **`/routes` 호출 통합** — 편집 진입·복귀가 3회 → 1회
  - 상세 응답 분류 필드 누락 내구성, 명세 정합(`isUsed` 전송·요약 필드), `UserRepository` 에러 계약 통일

### 다음
- [ ] **AI 기능 착수** — 서버 준비 완료(`/ai/routes/adjustments/text`·`/voice`,
      `/routes/recommendations`, `/user/{id}/riding-profile`), `routeSummaryId` 보관 완료
- [ ] `PathSimplifier` + `PathSimplificationMetrics` + perf A/B 로깅
- [ ] RidingViewModel Mock 시나리오 테스트 확대
- [ ] LocationManager 이중 인스턴스 정리 (`MapViewController.locationManager` vs `userLocationManager`)

### 보류 (판단이 끝났고 지금은 안 함)
- **라이딩 시작의 `/routes/guide` 통합** — `/routes/guide`와 `/routes`는 같은
  `RouteGuideRespDto`를 반환한다(실측 응답이 86110B로 바이트 동일). 라이딩 시작 한 번에
  같은 재계산이 두 번 간다. 다만 `getRouteGuideAPI`는 단순 조회가 아니라
  `postRidingStartAPI`로 경로를 "사용 중"으로 바꾼 **직후에** 읽는 오케스트레이션이고,
  비정상 종료 복구 분기(`isNotNormal`)까지 얽혀 있어 순서 의존 검증이 선행돼야 한다
- **에러를 사용자에게 노출** — 실패가 전부 `print`로만 남는다. 서버 500이 정리된 뒤
  남는 실패(네트워크 끊김 등)를 보고 표시 방식을 정하기로 했다

### 기술 부채
- **`POST /routes` 본문 조립이 `SpotAddViewModel`·`DetailSpotViewModel`에 복붙돼 있음**
  — 두 화면이 같은 본문을 만드는지는 `RouteAddRequestTests.bothEntryPointsProduceIdenticalRequestBody`가 잠근다.
  공용 빌더(`RouteRequestBuilder`) 추출은 미완
- `POST /routes` 응답 타입 불일치 (`RoutesModel` vs `EmptyResponse`)
- `UserRepository`의 요청 조립만 `NetworkService` 밖에 남음
  (세션·상태 판정·에러 타입은 통일 완료)
- `print` → OSLog

---

## AI 에이전트 규칙

**DO**: 실패하는 테스트 먼저, minimal diff, protocol DI, NMaps와 pure logic 분리, `@MainActor` UI 업데이트, 한국어 응답

**DON'T**: 테스트 없이 프로덕션 코드 작성, 컴파일 에러를 RED로 간주, `project.pbxproj` 편집, View에 오케스트레이션 추가, `RouteRepository.shared` 직접 참조로 Mock 우회, git commit/push (명시 요청 시만), 시크릿 커밋 (LLM API 키를 `Config.xcconfig`/Info.plist에 넣지 마라 — 앱 바이너리에 실린다), 경유지 DnD POST 후 `getRouteLocationAPI` 호출 (순서 덮어씀)

**새 fixture 추가 시**: JSON 파일 + `FixtureLoaderTests` 디코딩 검증

**커밋 메시지에 `Co-Authored-By: Claude ...` 트레일러를 넣지 마라.**
GitHub이 이걸 공동 작성자로 해석해 저장소 기여도에 표시한다.
이미 main에 들어간 14개(`bfb8cf8`~`9505123`)는 협업 중이라 되돌리지 않기로 했고,
앞으로 만드는 커밋에만 적용한다.

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
