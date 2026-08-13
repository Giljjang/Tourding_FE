# Riding AI 기능 — 레이어 배치와 테스트 이음새

AI 기능을 붙이기 전에 이 문서의 이음새를 먼저 만든다. 이음새 없이 시작하면 첫 테스트를 쓸 자리가 없다.

## 레이어 배치

기존 관례(`View → ViewModel → Repository(protocol) → NetworkService`)를 그대로 따른다. AI라고 새 아키텍처를 만들지 않는다.

```
SheetContentView (요약 카드 UI)
  → RidingViewModel+AI.swift          상태 전이 오케스트레이션
    → AIRouteRepositoryProtocol       ← 여기가 테스트 경계
      ├─ AIRouteRepository            NetworkService → 백엔드 프록시
      └─ MockAIRouteRepository        FixtureLoader (DEBUG)
    → AIPromptBuilder  (순수)         경로 데이터 → 요청 페이로드
    → AIResponseParser (순수)         LLM 텍스트 → 도메인 모델
```

**LLM 키를 앱에 넣지 않는다.** `AppConfig.swift`는 `Bundle.main.infoDictionary`에서 읽고, `Config.xcconfig`의 값은 Info.plist를 거쳐 앱 바이너리에 그대로 실린다. 프로바이더 키를 여기 넣으면 추출 가능하다. 호출은 기존 `BASE_URL` 백엔드에 엔드포인트를 추가해 프록시한다. 백엔드 일정 때문에 클라이언트 직접 호출을 택해야 한다면 그건 사람이 내릴 결정이지 에이전트가 기본값으로 정할 일이 아니다 — 물어봐라.

## 이음새 카탈로그

각 이음새는 **비결정적 부분을 한 곳에 몰아넣고 나머지를 순수 함수로 만드는** 것이 목적이다.

### 1. AIPromptBuilder — 순수 함수

```swift
enum AIPromptBuilder {
    static func courseSummaryPayload(
        locations: [LocationNameModel],
        total: RoutesModel
    ) -> AICourseSummaryRequest
}
```

같은 입력 → 같은 출력. 테스트: 3스팟 fixture + `routes_total_unused.json`(distance 12650 / duration 2588.8)을 넣으면 출발지·경유지 순번·도착지·거리·소요시간이 결정적으로 조립되는가.

**주의**: 좌표 순서. `RequestRouteModel`은 `경도,위도`인데 `splitCoordinateLatitude/Longitude`가 다루는 문자열은 `위도,경도`다. 프롬프트에 좌표를 넣는다면 어느 규약인지 테스트로 못 박아라.

### 2. AIResponseParser — 순수 함수

LLM 출력은 더럽다. 파서가 그걸 흡수한다.

```swift
enum AIResponseParser {
    static func parseSpotSuggestions(_ raw: String) throws -> [AISpotSuggestion]
}
```

최소 테스트 케이스:
- 정상 JSON
- ` ```json ` 펜스로 감싸인 JSON
- 앞뒤에 설명 문장이 붙은 JSON
- 개수 초과/미달 (3개 요청에 5개 응답)
- 깨진 JSON → `throw`
- 빈 문자열 → `throw`
- 이미 `routeLocation`에 있는 스팟 중복 제거

파서 테스트는 **인라인 JSON 문자열**로 쓴다. `FixtureLoader`의 기본 번들이 `.main`(= 앱 번들)이라 새 fixture 파일은 앱을 다시 빌드해야 로드된다. 순수 파서 테스트에 그 비용을 붙이지 마라. Repository fixture는 `Resources/Fixtures/`에 두고 `FixtureLoaderTests`에 디코딩 검증을 추가한다 (CLAUDE.md 규칙).

### 3. Repository 경계 — fake로 갈아끼우는 지점

```swift
protocol AIRouteRepositoryProtocol {
    func requestCourseSummary(_ request: AICourseSummaryRequest) async throws -> AICourseSummary
}
```

ViewModel 테스트는 이 프로토콜의 fake를 주입한다. 성공/실패/지연/취소를 fake가 결정한다. `NetworkService`는 `URLSession.shared`를 하드코딩하고 있어 HTTP 레벨 스텁 지점이 없다 — 그래서 테스트 경계는 **프로토콜**이지 네트워크가 아니다.

`DependencyProvider`에 `makeAIRouteRepository()`를 추가하고 기존 `MockAPIConfiguration.useMockAPI` 분기에 태운다. `AIRouteRepository()`를 ViewModel에 직접 넣지 마라.

### 4. 상태 머신 — ViewModel

```swift
enum AISummaryState: Equatable {
    case idle
    case loading
    case loaded(AICourseSummary)
    case failed(String)
}
```

단일 `enum`으로 둔다. `isLoading` + `summary` + `errorMessage` 세 개의 `@Published`로 쪼개면 "로딩 중인데 에러도 있는" 불가능한 상태가 표현 가능해지고, 그 조합은 테스트로 다 못 막는다.

테스트할 전이:
- idle → loading → loaded
- idle → loading → failed (repository throw)
- 경로 변경(DnD 재정렬, 스팟 추가/삭제) 시 캐시 무효화 → 재요청
- 진행 중 요청이 있을 때 새 요청이 오면 이전 요청 취소

### 5. 취소와 타임아웃

진행 중 `Task`를 프로퍼티로 들고 있어야 취소를 테스트할 수 있다. `reorderPersistTask`가 이미 쓰는 패턴이다.

```swift
var aiSummaryTask: Task<Void, Never>?
```

`RidingViewModel.updateToiletMarkers`처럼 `Task { }`를 내부에서 띄우고 밖으로 노출하지 않으면 **테스트에서 완료를 await할 방법이 없다**. AI 경로에서는 이 패턴을 반복하지 마라.

### 6. 폴백

AI 실패가 라이딩을 막으면 안 된다. 요약 실패 → 요약 영역만 숨기고 경로·가이드는 그대로. 이것도 테스트다: repository가 throw할 때 `routeLocation`/`guideList`가 손상되지 않는지 확인한다.

## 사이클 비용을 줄이는 선택지

호스팅 유닛테스트라 순수 함수 한 줄 검증에도 시뮬레이터 부팅 + 앱 전체 빌드가 붙는다 (웜 2분).

AI 기능은 순수 로직(빌더·파서) 비중이 커서 이 비용이 가장 크게 드러난다. 로컬 SPM 패키지(예: `TourdingCore`)로 빌더·파서·좌표/거리 계산을 옮기면 `swift test`가 초 단위로 돈다. 앱 타겟은 그 패키지를 의존한다.

이건 큰 변경이니 **사람에게 물어보고** 진행한다. 하지 않기로 했다면 위 명령의 사이클 비용을 받아들이되, 그것이 테스트를 몰아 쓰는 근거가 되지는 않는다.

## AI 기능 전 선행 리팩토링 (필수)

"언젠가 할 일"이 아니라 **첫 AI 테스트를 쓰기 전에 끝내야 하는 것**이다. 1번 없이는 ViewModel 테스트가
전부 guard에 막혀 의미 있는 어서션을 쓸 수 없다.

1. `RidingViewModel.init`의 `KeychainHelper.loadUid()` 직접 호출 → 주입 가능하게 (`UserSessionProviding`)
2. `Task { }` 내부 생성 → `Task` 프로퍼티 보관 (완료 await 가능하게)
3. 마커 번호 계산을 `NMFOverlayImage`가 아닌 순수 값(`enum RouteMarkerKind` / `[Int]`) 반환으로 분리

**이 리팩토링 자체의 순서**: 동작을 바꾸지 않는 구조 변경이므로, 기존 동작을 고정하는 특성화 테스트를 먼저 쓰고
(그것이 RED가 아니라 처음부터 GREEN이어도 된다 — 이건 안전망이지 새 기능이 아니다) 그 다음 구조를 바꾼다.
바꾸는 도중 그 테스트가 빨개지면 리팩토링이 아니라 동작 변경이다.

## 두 가지 사소한 규정

**Mock repository는 fixture 파일이 없어도 된다.** 인라인 상수를 반환해도 무방하다.
"새 fixture 추가 시 `FixtureLoaderTests` 디코딩 검증"(CLAUDE.md)은 **JSON 파일을 실제로 추가했을 때만** 적용된다.

**`DebugSessionLogger`를 AI 경로에 넣지 마라.** 이 로거는 `127.0.0.1:7674`로 실제 POST를 쏘며
릴리즈 빌드에서도 동작한다(파일에 `#if DEBUG`가 없다). 제거 대상이지 확산 대상이 아니다.
