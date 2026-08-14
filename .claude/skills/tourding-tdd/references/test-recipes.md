# Swift Testing 레시피 (Tourding_FE)

기존 `Tourding_FETests/FixtureLoaderTests.swift` 스타일을 따른다: `struct` + `@Test` + `#expect`.
XCTest를 새로 쓰지 마라.

## 1. 순수 함수 (가장 싸고 가장 먼저 쓸 테스트)

```swift
import Testing
@testable import Tourding_FE

struct RidingFormatTests {

    @Test func formatsDistanceUnderOneKilometerInMeters() {
        #expect(RidingViewModel.formatDistance(69) == "69m")
    }

    @Test(arguments: [
        (0.0, ""),
        (59.0, ""),
        (60.0, "1분"),
        (3600.0, "1시간"),
        (3660.0, "1시간 1분"),
    ])
    func formatsSecondsToHoursMinutes(seconds: Double, expected: String) {
        #expect(RidingViewModel.formatSecondsToHoursMinutes(seconds) == expected)
    }
}
```

`@Test(arguments:)`로 케이스를 늘려라. 케이스마다 `@Test`를 복사하지 마라.

## 2. throw 검증

```swift
@Test func rejectsMalformedLLMResponse() {
    #expect(throws: (any Error).self) {
        try AIResponseParser.parseSpotSuggestions("이건 JSON이 아닙니다")
    }
}
```

특정 에러 타입을 요구할 땐 `#expect(throws: AIParseError.self) { ... }`.

## 3. 언래핑은 `try #require`

```swift
@Test func decodesFirstWaypoint() throws {
    let locations: [LocationNameModel] = try FixtureLoader.load("routes_location_name_with_waypoints.json")
    let waypoint = try #require(locations.first { $0.type == "WayPoint" })
    #expect(waypoint.sequenceNum == 1)
}
```

`#expect(optional != nil)` 후 `!`로 강제 언래핑하지 마라. 실패 시 크래시로 스위트 전체가 죽는다.

## 4. Fake Repository — ViewModel 테스트의 이음새

프로토콜 fake는 **테스트 파일 안에** 둔다. 프로덕션 타겟에 테스트 전용 코드를 넣지 마라.

```swift
private final class FakeRouteRepository: RouteRepositoryProtocol {
    var locationsToReturn: [LocationNameModel] = []
    var errorToThrow: Error?
    private(set) var getRoutesLocationNameCallCount = 0

    func getRoutesLocationName(userId: Int, isUsed: Bool) async throws -> [LocationNameModel] {
        getRoutesLocationNameCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return locationsToReturn
    }

    // 나머지는 이 테스트에서 쓰지 않으므로 도달 시 실패시킨다
    func postRoutes(requestBody: RequestRouteModel) async throws { fatalError("unused") }
    func getRoutesPath(userId: Int, isUsed: Bool) async throws -> [RoutePathModel] { [] }
    func getRoutesGuide(userId: Int, isUsed: Bool) async throws -> [GuideModel] { [] }
    func getRoutes(userId: Int, isUsed: Bool) async throws -> RoutesModel { fatalError("unused") }
    func getRoutesRidingRecommend(pageNum: Int) async throws -> [RouteRidingRecommendModel] { [] }
    func postRoutesByName(requestBody: ReqRoutesByNameModel) async throws -> RoutesModel { fatalError("unused") }
}
```

**호출 횟수(`callCount`)만 검증하는 테스트는 쓰지 마라.** 그건 mock의 동작을 검증하는 것이지 프로덕션 코드를 검증하는 게 아니다. 호출 횟수는 "중복 요청을 안 보낸다" 같은 **동작 자체가 명세일 때만** 의미가 있다.

## 4-1. 요청 바디 검증에는 Spy가 필요하다

`MockRouteRepository.postRoutes`는 `requestBody`를 받고 **버린다**(`scenario`만 갱신). 그래서 기존 Mock으로는
"경유지 DnD 후 POST body의 `wayPoints` 순서가 맞는가" 같은 가장 중요한 검증을 할 수 없다.

요청을 검증하려면 테스트 파일에 캡처하는 spy를 따로 둔다:

```swift
private final class SpyRouteRepository: RouteRepositoryProtocol {
    private(set) var capturedRequests: [RequestRouteModel] = []

    func postRoutes(requestBody: RequestRouteModel) async throws {
        capturedRequests.append(requestBody)
    }
    // 나머지 생략
}

@Test func sendsWaypointsInDraggedOrder() async throws {
    let spy = SpyRouteRepository()
    // ... 재정렬 수행 ...
    let body = try #require(spy.capturedRequests.last)
    #expect(body.wayPoints == "127.1,37.1|127.2,37.2")   // 경도,위도 순
}
```

## 5. ViewModel 상태 전이

```swift
@MainActor
struct RidingViewModelLoadTests {

    @Test func populatesRouteLocationOnSuccess() async {
        let repository = FakeRouteRepository()
        repository.locationsToReturn = [
            LocationNameModel(sequenceNum: 0, name: "출발", type: "Start", typeCode: "A01",
                              contentId: "1", contentTypeId: "12", lon: "127.0", lat: "37.0")
        ]
        let viewModel = RidingViewModel(routeRepository: repository,
                                        kakaoRepository: FakeKakaoRepository())
        viewModel.userId = 3   // init에서 Keychain을 직접 읽으므로 테스트에서 덮어쓴다

        await viewModel.getRouteLocationAPI()

        #expect(viewModel.routeLocation.count == 1)
        #expect(viewModel.isLoading == false)
    }
}
```

`userId` 대입은 **우회지 이음새가 아니다**. 새 코드에는 주입 가능한 형태를 쓰고, 기존 코드는 리팩토링 대상으로 남긴다.

## 6. 시간에 의존하지 않기

```swift
// ❌ 나쁨 — 느리고 간헐적으로 깨진다
try await Task.sleep(nanoseconds: 500_000_000)
#expect(viewModel.state == .loaded)

// ✅ 좋음 — 대상 async 함수를 직접 await
await viewModel.loadCourseSummary()
#expect(viewModel.state == .loaded)
```

await할 대상이 없다면(내부에서 `Task { }`를 띄우고 밖으로 노출하지 않는 구조) 그건 테스트 문제가 아니라 **설계 문제**다. `Task`를 프로퍼티로 노출하도록 고쳐라.

`MockRouteRepository`를 쓸 때는 `simulatedDelayNanoseconds = 0`으로 두어라 (기본값 300ms).

## 7. Fixture

```swift
let guides: [GuideModel] = try FixtureLoader.load("routes_guide_with_waypoints.json")
```

`FixtureLoader`의 기본 번들은 `.main`이고, 호스팅 테스트라 `.main`은 앱 번들이다. 그래서:
- 기존 fixture는 그대로 로드된다
- **새 fixture를 추가하면 앱 타겟이 다시 빌드돼야 로드된다**
- 순수 파서 테스트는 fixture 대신 **인라인 문자열**을 써서 사이클을 짧게 유지한다

새 fixture를 추가했다면 `FixtureLoaderTests`에 디코딩 검증을 함께 추가한다 (CLAUDE.md 규칙).

## 8. NMapsMap이 섞인 코드

`NMFOverlayImage`, `NMFMapView`, `MarkerManager`는 테스트에서 검증 대상이 아니다. 대신:

- `markerCoordinates`, `markerIcons`, `guideList` **세 배열의 길이/순서 정합성**을 검증한다
- `mapView`, `markerManager`가 `nil`이면 지도 갱신 코드는 guard로 빠져나가므로 헤드리스 호출이 가능하다
- 순수 판정 로직(거리 계산, 인덱스 선택)은 `NMGLatLng` 배열을 직접 주입해 검증한다

## 함정 (실제 확인된 것)

- `Model/Search/SpotSearchModels.swift`는 `membershipExceptions`로 **테스트 타겟에도 컴파일**된다. `SpotData` 등이 두 모듈에 중복 존재해 `@testable import` 후 참조하면 ambiguous 에러가 난다.
  → `Tourding_FETests/`에 **테스트 파일**을 만드는 것은 안전하다(자동 편입). 금지되는 것은 `Tourding_FE/` 아래 **앱 소스 파일**을 테스트 타겟 멤버십에 추가하는 것이다. 스팟 검색 쪽을 TDD로 건드릴 거면 기존 예외부터 정리해야 한다
- `DebugSessionLogger.log()`가 `127.0.0.1:7674`로 실제 POST를 쏜다. `getRoutesTotalAPI` 성공 경로에 박혀 있어 ViewModel 테스트마다 실네트워크 부작용이 생긴다
- 호스팅 테스트라 `Tourding_FEApp.init()`이 실행된다 — `KakaoSDK.initSDK` 호출 + SplashView 표시. 순수 로직 테스트에도 앱 부팅 비용이 붙는다
- 테스트 타겟 deployment target이 18.5(앱 타겟은 17)다. 18.5 미만 시뮬레이터는 쓸 수 없다
- 빌드가 `Config.xcconfig`에 의존하는데 `.gitignore`의 `*.xcconfig`로 제외돼 있다. fresh clone·CI에서는 빌드 자체가 안 된다

## 현재 테스트가 **불가능한** 지점 (건드리려면 리팩토링이 선행되어야 함)

새 코드는 이 함정을 반복하지 마라.

| 지점 | 이유 |
|------|------|
| `LocationManager` | `init()`이 `requestWhenInUseAuthorization()`을 호출한다. 인스턴스 생성만으로 권한 프롬프트가 뜨고, 위치 이벤트 주입 지점이 없다 |
| `RidingViewModel+Lifecycle` 전반 | 구상 타입 `LocationManager`를 파라미터로 받는다. 프로토콜이 아니라 fake 주입 불가 |
| `PathManager` | `init(mapView: NMFMapView)` — 살아있는 지도 없이 인스턴스화 불가. Douglas-Peucker 로직이 여기 묶여 있다 |
| `makeMarkerIcons(for:)` | `NMFOverlayImage`를 반환해 `numberMarker(1)`과 `numberMarker(2)`를 값으로 구분할 수 없다. **경유지 번호 계산은 `[Int]`/enum을 반환하는 순수 함수로 분리해야 검증 가능** |
| `NetworkService` | `URLSession.shared` 하드코딩. 실제 Repository의 엔드포인트/파라미터 조립은 검증 불가. 테스트 경계는 Repository 프로토콜이다 |
## `private` 멤버는 대부분 장벽이 아니다

**접근 제어자를 바꾸기 전에 internal 호출자를 먼저 찾아라.**

예: `checkAndRemovePassedMarkers`와 `calculateDistance`는 `private`이지만, 호출자
`updateUserLocationAndCheckMarkers(_:)`는 internal이다. `mapView`/`markerManager`가 `nil`이면 지도 갱신은 guard로
빠져나가므로 **헤드리스로 완주한다** — 좌표를 넣고 `guideList`/`markerCoordinates`의 결과 상태를 단언하면
프로덕션 코드를 한 줄도 건드리지 않고 RED를 만들 수 있다.

호출자가 정말 없을 때만 `private` → `internal`로 넓힌다. 이때는 **접근 제어자만** 바꾸고 로직은 손대지 않으며,
순서가 뒤집혔다는 사실을 커밋 메시지에 남긴다.

임계값 상수(`markerPassThreshold = 30.0`)처럼 주입 불가능한 값은, 상수를 여는 대신 **그 값을 전제로 좌표를
배치한 테스트**를 먼저 써라. 상수를 파라미터로 여는 것은 테스트가 통과한 뒤의 REFACTOR다.
