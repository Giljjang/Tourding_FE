---
name: tourding-tdd
description: Use when implementing any feature or bugfix in Tourding_FE — especially Riding AI features (코스 요약, 경유지 추천, 자연어 안내) — before writing implementation code
---

# Tourding_FE TDD

## 철칙

```
실패하는 테스트 없이는 프로덕션 코드를 쓰지 않는다.
```

**규칙의 문자를 어기는 것은 규칙의 정신을 어기는 것이다.**

테스트보다 구현을 먼저 썼다면 → 지운다. 다시 시작한다.
- "참고용으로 남긴다" 안 된다
- "테스트 쓰면서 그걸 다듬는다" 안 된다
- 지운다는 건 지운다는 뜻이다

## RED의 정의 (계약)

RED는 **어서션 실패**다. 컴파일 에러는 RED가 아니다.

Swift에서 타입이 없으면 테스트 파일이 컴파일되지 않는다. 그래서 순서는 이렇다:

1. 테스트를 쓴다 (아직 없는 타입/메서드를 호출한다)
2. 컴파일을 통과시킬 **최소 껍데기**만 만든다 — 시그니처 + **중립 기본값** 반환 (빈 배열, `nil`, 기본 구조체)
3. 테스트를 돌린다 → **어서션이 실패하는 것을 눈으로 본다**
4. 실패 메시지가 "기능이 없어서"인지 확인한다 (오타·설정 문제가 아니라)
5. 통과할 만큼만 구현한다
6. 다시 돌려 초록을 확인한다
7. 초록을 유지하며 정리한다

껍데기에 **동작을 넣으면 위반**이다. 시그니처는 껍데기, 본문은 GREEN 단계.

**껍데기에 `fatalError("not implemented")`를 쓰지 마라.** 호스팅 테스트 러너에서 프로세스를 죽여 스위트 전체를 날린다.
그건 어서션 실패가 아니라 크래시이므로 3단계를 만족하지 못한다. 반드시 중립 기본값을 반환하게 하라.
(테스트 파일 안의 fake/spy에서 "이 테스트는 이 메서드를 안 쓴다"를 표현할 때만 `fatalError`가 적절하다.)

## 테스트 실행 (실측 검증된 명령)

```bash
xcodebuild test -scheme Tourding_FE \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -only-testing:Tourding_FETests \
  -derivedDataPath /tmp/TourdingDD
```

세 인자 모두 필수 이유 — 실제로 확인한 것:

| 인자 | 빼면 생기는 일 |
|------|----------------|
| `OS=18.5` | `Unable to find a device matching...` (exit 70). 테스트 타겟 deployment target이 18.5인데 `name=iPhone 16`만 쓰면 iOS 18.0 시뮬레이터로 잡힌다 |
| `-only-testing:Tourding_FETests` | 스킴 TestAction에 UI 테스트가 물려 있어 `Tourding_FEUITests`까지 돈다 |
| `-derivedDataPath` | Xcode가 열려 있으면 `build.db: database is locked` (exit 65) |

단일 테스트만: `-only-testing:Tourding_FETests/CourseSummaryTests/parsesFencedJSON`

같은 이름 + 같은 OS 시뮬레이터가 2대 이상이면 destination이 ambiguous해진다. 그럴 땐 UDID를 쓴다:
`-destination 'platform=iOS Simulator,id=<UDID>'` (`xcrun simctl list devices available`로 확인)

**결과를 파이프에 태우지 마라.** `xcodebuild ... | tail`은 exit code가 `tail`의 0으로 가려져 실패를 성공으로 오독한다.
로그는 파일로 리다이렉트하고 `echo $?`로 종료 코드를 확인한다.

**사이클 비용**: 콜드 3분 29초, 웜 2분 01초 (실측). 호스팅 테스트라 시뮬레이터 부팅 + 앱 전체 빌드가 매번 붙는다.
`-only-testing`은 UI 테스트의 **실행**만 건너뛴다 — 러너 앱 빌드·코드사인은 그대로 일어난다.

**새 테스트 파일은 `Tourding_FETests/`에 만들기만 하면 된다.** `project.pbxproj`가 `objectVersion = 77` + `PBXFileSystemSynchronizedRootGroup`이라 타겟에 자동 편입된다. pbxproj를 편집하지 마라.

## 무엇을 테스트하는가

경계를 정확히 그어라. "테스트 못 하는 영역"은 생각보다 훨씬 좁다.

| 반드시 테스트 | 테스트하지 않음 |
|---------------|-----------------|
| 프롬프트/요청 바디 조립 (순수 함수) | SwiftUI `body` 렌더링 |
| LLM 응답 파싱 — 정상/펜스(` ```json `)/깨진 JSON/빈 응답 | `URLSession.shared` 실제 통신 |
| ViewModel 상태 전이 — idle→loading→loaded/failed | NMFMapView에 실제로 그려진 픽셀 |
| 에러 폴백·타임아웃·취소 동작 | CLLocationManager의 실제 GPS 시퀀스 |
| 좌표 파싱·거리 계산·포맷 (`+Utils`) | Kakao SDK 로그인 플로우 |
| 배열 인덱스 정합성 (guideList ↔ markerCoordinates ↔ markerIcons) | |
| Fixture 디코딩 (`FixtureLoaderTests`) | |

"LLM은 비결정적이라 테스트 못 한다"는 **응답 본문에만** 해당한다. 프롬프트 조립, 파싱, 상태 전이, 폴백, 취소는 전부 결정적이다. Repository 경계에서 fake로 갈아끼우면 응답은 네가 고정한다.

## 버그 수정

버그를 재현하는 실패 테스트를 **먼저** 쓴다. 로그를 보며 고치지 않는다.

"읽자마자 틀린 게 보이는 명백한 버그"일수록 재현 테스트가 싸다. 재현 테스트 없이 고치면 같은 버그가 다른 경로로 돌아왔을 때 알 방법이 없다.

**무엇을 단언할 것인가**: 사용자가 관찰한 증상에 가장 가까운, 관측 가능한 상태를 고정하라.
"안내가 건너뛰어진다"면 → "특정 `sequenceNum`이 소비되기 전에 `guideList`에서 사라지지 않는다".
내부 구현(제거된 인덱스 집합)이 아니라 **증상의 대리 지표**를 명세로 삼아야 고치는 범위가 흔들리지 않는다.

**동시성 버그("가끔 발생")**: 타이밍을 재현하려 하지 마라. 레이스를 만드는 **상태 조합**을 직접 구성해 단언한다.
예 — 나중에 도착한 응답이 최신 상태를 덮는 버그는, fake repository가 오래된 스냅샷을 반환하도록 두고
그 사이 상태를 바꾼 뒤 "덮이지 않는다"를 단언하면 결정적으로 재현된다. 그래도 못 쓰겠으면
`Task.sleep`으로 때우지 말고 **왜 못 쓰는지**를 적어라 — 대개 격리(actor/`@MainActor`)가 없다는 설계 신호다.

## 합리화 표

베이스라인 측정에서 실제로 나온 말들이다. 이 문장이 머릿속에 떠오르면 멈춰라.

| 변명 | 현실 |
|------|------|
| "UI랑 네트워크는 어차피 못 하니 통째로 스킵" | 못 하는 건 SwiftUI body와 URLSession 경계뿐이다. Repository 요청 조립·에러 매핑·ViewModel 상태 전이는 전부 테스트 가능하다 |
| "LLM 응답이 비결정적이라 테스트가 무의미" | 비결정적인 건 응답 본문 하나뿐. 파서·빌더·폴백·취소는 결정적이다 |
| "컴파일 에러 났으니 RED 확인 완료" | 컴파일 에러는 RED가 아니다. 빈 껍데기로 컴파일을 통과시키고 어서션 실패를 봐라 |
| "한 사이클 2분이라 테스트 3~4개 몰아 쓰고 한 번에 돌린다" | 몰아 쓰면 어느 테스트가 왜 실패하는지 모른다. 사이클 비용이 문제면 순수 로직을 앱 의존 없이 뽑아라 (`references/ai-feature-seams.md`) |
| "타입을 먼저 만들어야 컴파일되니 TDD 순서가 어차피 깨진다" | 시그니처만 만드는 건 허용, 본문을 채우면 위반. 경계가 명확하다 |
| "print 로그 보면서 고치는 게 훨씬 빠르다" | 로그 디버깅은 재현 기록을 남기지 않는다. 다음 사람이 같은 자리에서 다시 헤맨다 |
| "이 프로젝트엔 ViewModel 테스트 선례가 0개라 나 혼자 하네스 뚫는 건 과하다" | 하네스는 이미 있다. 파일만 떨구면 타겟에 들어가고 명령은 위에 검증돼 있다 |
| "데모가 내일이라 동작하는 스파이크부터" | 스파이크는 버려라. 버릴 생각이 없다면 그건 스파이크가 아니라 테스트 없는 프로덕션 코드다 |
| "명백한 로직 버그라 그냥 고치면 된다" | 명백할수록 재현 테스트가 30초면 된다 |
| "LLM 응답 계약이 안 정해져서 지금 테스트 쓰면 추측을 고정시킨다" | 계약이 안 정해졌으면 계약을 정하는 게 첫 작업이다. 테스트가 그 계약이다 |

## Red Flags — 멈추고 다시 시작

- 구현이 테스트보다 먼저 있다
- 테스트가 처음부터 통과한다
- 왜 실패했는지 설명하지 못한다
- 컴파일 에러를 RED로 셌다
- "이번만", "이건 다르다", "정신은 지켰다"
- "이미 시뮬레이터에서 눈으로 확인했다"
- 껍데기라면서 본문에 로직을 넣었다

**전부 같은 뜻이다: 코드를 지우고 테스트부터 다시.**

## 참고

- Riding AI 기능의 레이어 배치와 테스트 이음새: `references/ai-feature-seams.md`
- Swift Testing 실제 코드 패턴 (fake repository, 상태 전이, 파서): `references/test-recipes.md`
- 프로젝트 관례 (protocol DI, extension 분리, 금지사항): `CLAUDE.md`, `.cursor/rules/`
