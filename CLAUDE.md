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

추적이 꺼져도 사용자가 `userMovementThreshold`(3m) 이상 움직이면
`resumeTrackingIfStopped()`가 자동으로 되켠다. 상태 전이는 `beginTracking()` 한 곳에 있다.

회귀 방지 테스트: `CameraFollowTests`

### 방위(heading) 판정 (중요)

**`HeadingResolver` 하나로 판정한다.** 카메라와 사용자 마커가 같은 원본을 쓰도록 강제한다.

NMap의 heading은 **진북 기준**이라 `magneticHeading`을 그대로 넣으면
편각만큼(서울 약 9도) 지도가 틀어져 회전한다. `trueHeading`은 Core Location이 편각을
이미 반영해 주므로 편각 상수를 들고 있을 필요가 없다 — 음수(구하지 못함)일 때만 자북으로 폴백한다.

`markerIconOffset`(-45)은 **편각 보정이 아니라 아이콘 에셋 보정**이다.
에셋을 교체하면 같이 바뀌어야 한다. 이 값을 호출부에 복제하지 말 것.

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

1. **바텀시트 카메라 피봇** — `RidingView.onChange(currentPosition)` 로직 ViewModel 이전 검토
2. **지도 터치 감지 레이어** — 추적 중에만 존재하고 지도 위에 얹혀 있어, 첫 드래그가
   추적만 끄고 지도는 밀리지 않는다 (`RidingView`의 투명 제스처 레이어)
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

### 다음
- [ ] **AI 기능 착수** — 서버 준비 완료(`/ai/routes/adjustments/text`·`/voice`,
      `/routes/recommendations`, `/user/{id}/riding-profile`), `routeSummaryId` 보관 완료
- [ ] **내비게이션 카메라** — 자동차 내비처럼 "경로가 화면에서 위로" (피봇 → course → 틸트 순)
      - **피봇** `cameraPivotY` 0.3 → 0.75. NMap 피봇은 `(0,0)`이 좌상단이라 지금은 사용자가
        화면 위쪽 30%에 놓인다 — 헤딩-업 회전을 걸어도 앞이 30%만 보인다. 한 줄, 체감 가장 큼
      - **틸트** 현재 0 (아무도 설정 안 함). `NMFMapView.maxTilt` 기본값 60, 내비 느낌은 45~55
      - **course** 우선순위 낮음 — **핸들바 거치를 전제**하기로 했다(2026-08-19 결정).
        거치 시 나침반 ≈ 진행 방향이라 이득이 작다.
        다만 완전히 무의미하지는 않다: 조향하면 폰도 같이 돌아 저속 코너에서 나침반이 튀고,
        **자석 거치대**는 자력계 바로 옆에 자석이 붙어 정확도가 무너진다.
        착수 시 한 줄 교체가 아니다 — `course`는 정지 중 무효(음수)라
        속도 임계값 + 히스테리시스 + 나침반 폴백이 필요하다.
        이음새는 이미 있다(`HeadingResolver`가 원시값 순수 함수, 테스트 8건)
      - 셋 다 **눈으로 보고 조정하는 값**이라 따로 하면 실기기 주행 테스트를 세 번 한다. 묶을 것

- [ ] **경로선 재그리기 가드** — `MapViewRepresentable.updateUIView`가 `updateMap()`을 무조건 부르고
      `PathManager.setCoordinates`가 좌표 비교 없이 매번 단순화 + 오버레이 전체 재부착을 한다.
      마커도 매번 전량 재생성(`MarkerManager.addMarkers`가 `clearMarkers`로 시작).
      **주의**: 좌표 *개수*로만 가드하면 DnD 재정렬이 반영되지 않는다
- [ ] `PathSimplifier` + `PathSimplificationMetrics` + perf A/B 로깅
      — Douglas-Peucker 실측: 258좌표 fixture에서 239개(7.4% 감소), 최대 이탈 0.87m.
      실효가 거의 없다. tolerance를 키우면 이탈이 10m대라 자전거 경로엔 못 쓴다.
      순수 타입 추출과 테스트가 먼저다 (현재 `PathManager` 테스트 0건)
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
