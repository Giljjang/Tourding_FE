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
| `+LocationTracking.swift` | 3m 이동 판정 + 추적 자동 재개(`userMovementThreshold`), 30m 마커 통과 |
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
LocationManager → HeadingResolver (방위 판정)
PathManager    → PathSimplifier (Douglas-Peucker, 순수 함수)
```

`MapViewRepresentable.updateUIView`에서 ViewModel에 `pathManager` 포함 전체 매니저 연결.
`LocationManager`는 여기서 주입하지 않는다 — `configureLocationManager` 참조.

### 지도 참조 소유권 (중요)

`RidingViewModel`의 지도 관련 프로퍼티는 **전부 `weak`**다.
소유자는 화면(`MapViewController` / `RidingView`의 `@StateObject`)이고 ViewModel은 앱 수명이므로,
strong으로 잡으면 화면을 떠난 뒤에도 `MapViewController`와 그 `CLLocationManager`가 살아 GPS가 계속 돈다.
`MapViewController.ridingViewModel`도 같은 이유로 `weak`.

`RecommendRouteViewModel` ↔ `RecommendMapViewController`도 같다.
이쪽은 ViewModel이 **화면 수명**(`@StateObject`)이라 순환이 나면 화면에 들어갈 때마다
한 세트씩 쌓인다 — 앱 수명인 라이딩 쪽(1세트 잔존)보다 나쁘다.

**새 지도 참조를 추가할 때도 `weak`을 유지할 것.**

`LocationManager`는 **화면당 하나**다. 소유자는 `RidingView`·`RecommendRouteView`의
`@StateObject` 하나뿐이고, `MapViewController`·`RecommendMapViewController`는
자체 인스턴스를 만들지 않고 주입만 받는다 — `configureLocationManager`가 ViewModel의
`locationManager`와 `userLocationManager`를 같은 객체로 맞춘다.
**`LocationManager`는 생성만으로 GPS가 켜지므로** VC에 저장 프로퍼티를 되살리면 스트림이 두 벌 돈다.

회귀 방지 테스트: `MapBindingLifetimeTests`, `RecommendMapBindingLifetimeTests`,
`SingleLocationManagerTests`

### 카메라 추적 판정 (중요)

**카메라가 사용자를 따라갈지는 `LocationManager.shouldFollowUser` 하나로 판정한다.**
"라이딩 중인가"(`flag`)가 아니라 **"추적 중인가"**(`isNavigationMode`)가 기준이다.
`flag`로 판정하면 사용자가 지도를 밀어 추적을 꺼도 다음 GPS 갱신(3m)에 카메라가 도로 스냅된다.

**카메라를 사용자에게 따라붙게 하는 코드는 전부 `followUser(on:to:)`를 거칠 것.**
호출부에서 `moveCamera`를 직접 부르면 판정이 복제된다 — 세 곳이 각자 판정하다
세 곳 모두 `flag`로 잘못 판정한 것이 이 버그였다.

**사용자가 지도를 민 것은 `NMFMapViewCameraDelegate`로 감지한다** —
`cameraWillChangeByReason:`의 `reason`이 `NMFMapChangedByGesture`인지 본다.
판정은 `LocationManager.isUserGesture(cameraChangeReason:)` 한 곳.

지도 위에 투명 레이어를 얹지 마라. 예전 방식이 그랬는데, ZStack에서 `NMapView`의
형제라 터치를 가로채 **첫 드래그에 지도가 밀리지 않았다**(두 번 밀어야 했다).
게다가 레이어는 우리 코드의 카메라 이동과 사용자 제스처를 구분할 수 없다 —
`reason`은 구분해준다(`Developer` / `Gesture` / `Location` / `Control`).

추적이 꺼져도 사용자가 `userMovementThreshold`(3m) 이상 움직이면
`resumeTrackingIfStopped()`가 자동으로 되켠다. 상태 전이는 `beginTracking()` 한 곳에 있다.

**줌은 라이딩 시작에만, 라이딩당 한 번만 맞춘다.**

**절대 줌을 쓰지 마라 — 현재 줌 기준 상대값(`ridingStartZoomDelta`)이다.**
처음에 절대값 16.5를 넣었다가 화면이 그대로였다. 실측 기준 줌이 **14.0**이라
16.5는 확대였지만 폭이 작았고, 무엇보다 기준을 모르는 채로 절대값을 정하면
편집 화면 줌이 그보다 크면 오히려 축소된다. 상대값이면 기준이 뭐든 확대된다.
(실측 로그: `14.0 → 17.0`, 지도 `maxZoomLevel`은 22)

**게이트는 `startNavigationMode` 안에서 연다** (`consumeRidingStartZoom`).
호출부에서 열면 위치가 없어 카메라를 못 옮기는 경우에도 소진돼 영영 걸리지 않는다.
시작 경로가 셋(`flag` 전이 · 시작 API · 비정상 복구)이라 그중 하나만 측위 전에 돌아도 잃는다.

추적 재개(`beginTracking`)에는 걸지 않는다 — 주행 중에 일어나므로 배율이 날아간다.

**줌을 바꿀 때는 애니메이션 없이** 맞춘다. 애니메이션 중에 헤딩 갱신이 끼어들면
`updateCameraWithHeading`이 `cameraPosition.zoom`으로 **중간 줌**을 읽어 그대로 굳힌다.

라이딩이 끝나면 시작 전 줌으로 되돌린다 — `restoreZoomBeforeRiding(on:)`.
뒤로가기(라이딩 중)와 종료 버튼이 둘 다 `endRiding`을 거치므로 한 곳이면 된다.
**복원이 `resetRidingStartZoom`보다 먼저**여야 한다 — 리셋이 기억해 둔 값을 비운다.

**사용자 위치 마커를 켜는 것도 잊지 말 것.** `NMFLocationOverlay`는 기본이 숨김이라
`showUserLocationOverlay(on:at:)`를 부르기 전에는 그려지지 않는다.
예전에는 "내 위치로 이동" 버튼과 라이딩 중 위치 콜백만 이걸 했고, `distanceFilter`가 3m라
정지 상태에서 라이딩을 시작하면 마커가 안 보였다.

**바텀시트 높이는 편집·라이딩 양쪽에서 피봇에 반영한다** — `syncCameraPivot(for:)`.
편집에서 빠뜨리면 "내 위치로 이동" 버튼이 시트 높이를 무시한다.

회귀 방지 테스트: `CameraFollowTests`, `CameraPivotTests`, `RidingStartZoomTests`, `MapGestureDetectionTests`

### 방위(heading) 판정 (중요)

**`HeadingResolver` 하나로 판정한다.** 카메라와 사용자 마커가 같은 원본을 쓰도록 강제한다.

NMap의 heading은 **진북 기준**이라 `magneticHeading`을 그대로 넣으면
편각만큼(서울 약 9도) 지도가 틀어져 회전한다. `trueHeading`은 Core Location이 편각을
이미 반영해 주므로 편각 상수를 들고 있을 필요가 없다 — 음수(구하지 못함)일 때만 자북으로 폴백한다.

카메라 방위도 이 타입을 거친다 — `cameraHeading(from:)`.
지도 회전 = 마커 방위 = `mapHeading`, 세 값이 모두 같다.

**보정 상수 `markerIconOffset`·`cameraHeadingOffset`은 현재 둘 다 `0`이다.**
편각 보정이 아니라 각각 아이콘 에셋·지도 회전을 보정하는 **별개 손잡이**이므로
한 값으로 묶지 말 것. 값은 호출부에 복제하지 말 것.

마커 보정은 **에셋 자체를 고쳐 없앴다** — `userMarker.imageset/Group 35465.svg`의
화살표 path에 `transform="rotate(-38.5 …)"`를 넣어 정북으로 맞추고 필터 영역을 넓혔다
(회전하면 화살표가 기존 필터 영역 위로 나가 잘린다).

**이 값을 SVG 좌표로 계산해서 넣지 마라.** 계산으로 유도하다 두 번 빗나갔고,
결국 실기기에서 눈으로 맞추는 데 일곱 번 걸렸다
(`-45 → -23.5 → -3.5 → +16.5 → +6.5 → -8.5 → -38.5 → 0`).
바꿀 일이 생기면 실기기에서 확인할 것.

이전에는 `LocationManager`가 자북에서, `MapViewController`가 진북 우선에서 각각 -45를 빼
같은 `locationOverlay.heading`에 서로 다른 기준의 값을 썼다.

회귀 방지 테스트: `HeadingResolverTests`

### 마커 통과 판정 (A)

임계값(30m) 안에 마커가 있으면 **맨 앞 한 칸만** 소비한다.
이전에는 "가장 가까운" 마커를 찾아 `0...그 인덱스`를 한꺼번에 지워서,
30m 안에 마커가 둘 이상이거나 GPS가 튀면 중간 안내가 화면에 한 번도 뜨지 않고 사라졌다
(실제 fixture에 20.7m·21.2m 간격 구간이 있다).

여러 칸 밀리면 다음 위치 갱신들로 따라잡는다 — 콜백이 3m 이동마다 오므로 두 칸이면 약 6m 주행이다.
회귀 방지 테스트: `MarkerPassingTests`

### 미해결 이슈

1. **바텀시트 카메라 피봇** — 값 매핑은 `LocationManager.cameraPivot(for:)`로 옮겼으나,
   `RidingView.onChange(currentPosition)`의 카메라 이동 오케스트레이션은 아직 View에 있다
2. **마커 재그리기** — 경로선은 `PathManager.isSameSequence`로 가드했지만
   `MarkerManager.addMarkers`는 여전히 `clearMarkers()`로 시작해 매번 전량 재생성한다.
   가드를 걸려면 아이콘 동일성 판정이 먼저다 — `MarkerIcons.numberMarker(_:)`가
   호출마다 `UIView`를 렌더링해 새 `NMFOverlayImage`를 만든다
3. **`POST /routes` 응답을 버리는 호출부** — 호출 6곳 중 응답을 쓰는 곳은 라이딩 시작 하나뿐.
   특히 경유지 DnD는 응답을 버리고 `GET /routes/path`를 다시 부른다
   (단 `applyRouteBundle`을 그대로 쓰면 `locations`까지 반영돼 드래그 순서가 덮인다 — path만 골라야 한다)

---

## 네트워크 계약

**경로 조회는 `getRouteBundle` (`GET /routes`) 하나로 받는다.**
서버가 요약·`guides`·`paths`·`locations`를 한 응답에 담아준다(`RouteGuideRespDto`).
개별 엔드포인트를 각각 부르면 서버가 같은 경로를 여러 번 재계산한다 —
응답 하나가 80KB대이고, 실측상 짧은 세션에 `/routes` 200 응답만 12회 나간 뒤
`/routes`·`/routes/path`·`/routes/guide`가 연쇄 500을 반환했다.

**`POST /routes` 응답을 버리지 마라.** 서버가 요약·`guides`·`paths`·`locations`를
전부 돌려준다. 라이딩 시작은 이 응답을 재사용하고 `GET /routes/guide`를 부르지 않는다.

**번들 반영은 `applyRouteBundle` / `applyGuideMarkers` 두 함수로만 한다.**
`POST /routes`·`GET /routes`·AI 경로 재설정이 모두 같은 `RouteGuideResponse`를 돌려주므로
반영 경로를 하나로 유지한다. 새로 만들지 말 것.

**"백업 후 교체" 순서를 지켜라.**
```
장소(locations) 기준 마커 → backupOriginalData() → 안내(guides) 기준으로 교체
```
라이딩 종료 시 `restoreOriginalData`가 백업본으로 되돌린다. 순서가 뒤집히면
종료 후 안내 마커가 남는다. 회귀 방지 테스트: `RidingStartRecoveryTests`

**응답 모델의 새 필드는 옵셔널로 둔다.** 필드 하나 때문에 응답 전체가 폐기되는 실패를
두 번 겪었다(`/routes/guide` 형태 변경, 상세의 분류 필드 누락).

**재시도는 될 만한 것에만.** `ErrorType.isRetryable` —
408·429·503·네트워크 단절만 재시도하고 **500·502·504·4xx는 즉시 중단**한다.
이 서버의 500은 결정적이다(실측: `/routes/path` 500이 3회 연속 동일).
**재시도 루프를 직접 만들지 마라 — `RetryPolicy.run`을 쓸 것.**
정책이 흩어져 있으면 다섯 번째 루프에서 가드를 빠뜨린다.
ViewModel 4곳에 복붙돼 있던 것을 이 한 곳으로 모았다.

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

- [x] **라이딩 시작을 POST /routes 응답 재사용으로 통합 (TDD)** — 테스트 135개
  - 서버가 POST 응답으로 경로 전체를 돌려주는데 앱이 버리고 GET으로 다시 받았다
    (실측: POST 응답과 GET /routes/guide 응답이 86110B로 바이트 동일)
  - 정상 시작 2회 → 1회, 비정상 복구 5회 → 2회
  - 반영 로직을 `applyRouteBundle` / `applyGuideMarkers`로 추출 — 편집 모드도 같은 함수를 쓴다
  - 손대기 전에 특성화 테스트(`RidingStartRecoveryTests`)로 현재 동작을 먼저 잠갔다

- [x] **라이딩 카메라·방위·위치 인스턴스 정리 (TDD)** — 테스트 168개, 스킵 0
  - **추적을 꺼도 카메라가 스냅** — 카메라를 옮기는 세 곳이 `isNavigationMode`가 아니라
    `flag`로 판정했다. 지도를 밀어놔도 다음 GPS 갱신(3m)에 도로 돌아왔다.
    판정을 `shouldFollowUser` / `followUser(on:to:)` 한 곳으로 모았다
  - **3m 이동 시 추적 자동 재개** — `resumeTrackingIfStopped()` + `userMovementThreshold` 상수화.
    주의: 15km/h에서 3m는 약 0.7초다. 지도를 살펴볼 여유를 주려면 이 값을 키워야 한다
  - **지도가 자북 기준으로 회전** — NMap의 heading은 진북 기준인데 `magneticHeading`을
    그대로 넣어 한국에서 약 9도 틀어졌다. `HeadingResolver`로 판정을 모으고 `trueHeading` 우선으로.
    `-45` 하드코딩 2곳도 `markerIconOffset` 하나로 통합
  - **LocationManager 이중 인스턴스** — 라이딩·추천 코스 두 화면 모두 VC가 자체 인스턴스를
    소유해 GPS가 두 벌 돌았다. 추천 코스 쪽은 콜백조차 없이 `startLocationUpdates()`만 불렀다.
    VC의 저장 프로퍼티를 없애고 주입만 받게 했다
  - **스팟 추가 POST 실패 시 로딩 미해제** — `isLoading` 해제가 `do` 블록 안에만 있었다

- [x] **지도 성능·정리 (TDD)** — 테스트 215개, 스킵 0
  - **경로선을 SwiftUI 갱신마다 재생성** — `updateUIView`가 `updateMap()`을 무조건 부르고
    `setCoordinates`가 좌표 비교 없이 매번 단순화 + 오버레이 전체 재부착을 했다.
    `PathManager.isSameSequence`로 가드. 개수만 비교하면 DnD 재정렬이 반영되지 않고,
    `NMGLatLng`은 클래스라 참조 비교면 가드가 아예 안 먹는다
  - **`PathSimplifier` / `PathSimplificationMetrics` 분리** — 특성화 테스트로 현재 동작을
    먼저 잠근 뒤 옮겼다 (258좌표 → 239개, `count <= 3`은 줄이지 않음 — 교과서와 다르지만 보존)
  - **`RetryPolicy` 단일화** — ViewModel 4곳의 복붙 루프 제거
  - **릴리즈 로그 유출** — `NetworkService`의 요청 URL·본문·에러 응답 전문에 `#if DEBUG` 가드.
    URL 쿼리에 `authorizationCode`가 실리는 엔드포인트가 있다
  - **마커·카메라 방위 정합** — 보정 상수 둘 다 0으로, 에셋을 정북으로 교정
  - **라이딩 시작 시 마커 미표시 / 편집 모드 피봇 동기화**
  - **라이딩 시작 줌** — 시작에만 1회 적용하고 종료 시 복원.
    절대값으로 두었다가 안 걸려 6커밋을 썼다. 기준 줌을 모르는 채 값을 짐작한 것이 원인이다.
    진단 로그를 먼저 넣었으면 한 번에 끝났을 일이다
  - 빈 catch 2건, 죽은 코드 5건(+`onMapTap` 배선 전부) 정리

### 다음
- [ ] **AI 기능 착수** — 서버 준비 완료(`/ai/routes/adjustments/text`·`/voice`,
      `/routes/recommendations`, `/user/{id}/riding-profile`), `routeSummaryId` 보관 완료
- [ ] **내비게이션 카메라** — 자동차 내비처럼 "경로가 화면에서 위로" (피봇 → course → 틸트 순)
      - **피봇 값** 기본 0.3 → 0.75 검토. NMap 피봇은 `(0,0)`이 좌상단이라 지금은 사용자가
        화면 위쪽 30%에 놓인다 — 헤딩-업 회전을 걸어도 앞이 30%만 보인다.
        매핑은 `LocationManager.cameraPivot(for:)`에 모여 있으니 값만 바꾸면 된다
      - **틸트** 현재 0 (아무도 설정 안 함). `NMFMapView.maxTilt` 기본값 60, 내비 느낌은 45~55
      - **course** 우선순위 낮음 — **핸들바 거치를 전제**하기로 했다(2026-08-19 결정).
        거치 시 나침반 ≈ 진행 방향이라 이득이 작다.
        다만 완전히 무의미하지는 않다: 조향하면 폰도 같이 돌아 저속 코너에서 나침반이 튀고,
        **자석 거치대**는 자력계 바로 옆에 자석이 붙어 정확도가 무너진다.
        착수 시 한 줄 교체가 아니다 — `course`는 정지 중 무효(음수)라
        속도 임계값 + 히스테리시스 + 나침반 폴백이 필요하다.
        이음새는 이미 있다(`HeadingResolver`가 원시값 순수 함수, 테스트 8건)
      - 셋 다 **눈으로 보고 조정하는 값**이라 따로 하면 실기기 주행 테스트를 세 번 한다. 묶을 것

- [ ] **마커 재그리기 가드** — 경로선은 끝났지만 `MarkerManager.addMarkers`가 여전히
      `clearMarkers()`로 시작해 매번 전량 재생성한다. 선행: 아이콘 동일성 판정
      (`MarkerIcons.numberMarker(_:)`가 호출마다 `UIView`를 렌더링해 새 이미지를 만든다)
- [ ] perf A/B 로깅 — `PathSimplificationMetrics`는 있으나 소요 시간·A/B 스위치는 없다.
      Douglas-Peucker 실측: 258좌표에서 239개(7.4% 감소), 최대 이탈 0.87m.
      실효가 거의 없어 제거도 선택지다
- [ ] RidingViewModel Mock 시나리오 테스트 확대
      — `RidingViewModel`을 만드는 14개 파일이 전부 `FakeRouteRepository`를 쓴다.
      `MockRouteRepository` 시나리오(`.withWaypoints`/`.simple`) 기반 테스트는 0건.
      미커버: `+Utils` 전부, `+Lifecycle`의 진입·복귀·포그라운드

### 보류 (판단이 끝났고 지금은 안 함)
- **에러를 사용자에게 노출** — 실패가 전부 `print`로만 남는다. 서버 500이 정리된 뒤
  남는 실패(네트워크 끊김 등)를 보고 표시 방식을 정하기로 했다

### 기술 부채
- **`POST /routes` 본문 조립이 `SpotAddViewModel`·`DetailSpotViewModel`에 복붙돼 있음**
  — 두 화면이 같은 본문을 만드는지는 `RouteAddRequestTests.bothEntryPointsProduceIdenticalRequestBody`가 잠근다.
  공용 빌더(`RouteRequestBuilder`) 추출은 미완
- `POST /routes` 응답을 버리는 호출부 — 6곳 중 소비는 라이딩 시작 하나뿐
  (`EmptyResponse`는 선언만 남은 데드 타입)
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
