# ue-widget-creator 가이드

이 문서는 `WidgetSemanticBridge` 플러그인과 함께 `ue-widget-creator` skill 을 사용하여 AI Agent 가 정적 UI와 위젯 애니메이션 DSL을 생성하고, 검증하고, 미리 보고, UMG Widget Blueprint 로 가져오는 방법을 설명합니다.

![커버](../assets/cover_main.jpg)

## 이것은 무엇인가

`ue-widget-creator` 는 AI Agent 를 위해 설계된 워크플로 skill 입니다.

이것은 Unreal 런타임 코드도 아니고, 독립 실행형 플러그인도 아닙니다. 목적은 AI Agent 가 다음 작업을 수행하도록 안내하는 것입니다.

- UI 요구사항 분석
- 요구사항을 지원되는 `.widgetdsl` 로 변환
- 생성 범위를 `WidgetSemanticBridge` 가 지원하는 위젯, 프로퍼티, 슬롯, 애니메이션 트랙 안으로 제한
- `animation` / `track` 섹션 생성 또는 수정
- 가져오기 전에 검증과 미리보기 실행
- 검증된 DSL을 Unreal 의 실제 `WBP_*` 애셋으로 가져오기

## WidgetSemanticBridge 와의 관계

이 구성은 두 부분으로 이루어져 있습니다.

- `WidgetSemanticBridge`: 검증, 미리보기, 가져오기를 담당하는 [Unreal Editor 플러그인](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f)
- `ue-widget-creator`: 요구사항 분석과 DSL 생성 워크플로를 담당하는 AI Agent skill

플러그인은 실제 작업을 실행하고, skill 은 워크플로를 정의합니다.

## 게임 UI 개발을 어떻게 개선하는가

게임 프로젝트에서는 게임플레이, 밸런스, 비주얼 디자인이 계속 바뀌면서 UI를 반복해서 수정해야 하는 경우가 많습니다. `WidgetSemanticBridge` 플러그인과 `ue-widget-creator` 를 함께 사용하면 “요구사항 설명 -> DSL 생성 -> 검증 / 미리보기 -> Blueprint 로 가져오기”를 반복 가능한 워크플로로 만들 수 있어, 수작업으로 UMG를 구성하고 에디터를 반복해서 클릭하는 시간을 크게 줄일 수 있습니다.

주요 이점은 다음과 같습니다.

- 인벤토리, 메인 메뉴, 퀘스트 패널, 팝업 같은 화면의 UI 프로토타입을 더 빠르게 만들 수 있음
- 디자인 목업, 스케치, 문서화된 요구사항을 가져올 수 있는 Widget Blueprint 로 더 빠르게 변환하여 구현 과정의 정보 손실을 줄일 수 있음
- 레이아웃과 애니메이션의 일부가 `.widgetdsl` 텍스트로 표현되므로, AI가 UI 설명을 더 쉽게 이해하고 생성하고 수정할 수 있어 UI 상호작용, 상태 전환, 흐름 조정을 더 빠르게 반복할 수 있음
- 생성되거나 다시 내보낸 DSL은 AI가 UI 로직을 작성하는 데도 사용할 수 있음. WBP를 수정한 뒤 DSL을 다시 내보내면 AI가 변경된 UI에 맞춰 로직을 업데이트할 수 있어, UI 코드를 한 줄씩 직접 작성해야 하는 부담을 줄일 수 있음. 특히 Lua, TypeScript, Python 같은 스크립트 언어에 적합하며, C++ 또는 Blueprint 보다 AI가 더 빠르게 반복하기 좋음
- 가져오기 전 검증과 미리보기를 통해 지원되지 않는 위젯, 프로퍼티, 레이아웃 문제를 더 일찍 발견하여 재작업을 줄일 수 있음
- `.widgetdsl` 파일의 일괄 생성과 수정은 팀 협업과 자동화 워크플로에 더 적합하며, UI 애셋을 버전 관리하기 쉽게 만듦
- 구조적인 UI 작업을 플러그인과 skill 이 처리하면, 개발자는 게임플레이 로직, 상호작용 다듬기, 런타임 동작 구현에 더 많은 시간을 쓸 수 있음

## 설치

### 1. 플러그인 설치

플러그인 링크: [WidgetSemanticBridge](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f)

플러그인을 Fab 에서 가져오는 경우, 보통 `Install to Engine` 을 통해 Unreal Engine 디렉터리에 설치합니다.

`WidgetSemanticBridge` 는 두 가지 설치 방식을 모두 지원합니다.

- 프로젝트 플러그인: `<Project>/Plugins/WidgetSemanticBridge`
- 엔진 플러그인: `<Engine>/Plugins/.../WidgetSemanticBridge`

설치한 뒤 프로젝트에서 플러그인을 활성화합니다. Unreal Editor 에서 `Edit` -> `Plugins` 로 이동한 다음, `WidgetSemanticBridge` 를 찾아 활성화하세요.

### 2. skill 배치

Unreal Editor 에서 `AIBridge` -> `Widget Semantic Bridge` 를 연 다음, `Agent Skill Setup` 을 사용해 플러그인에 포함된 skill 을 프로젝트로 복사합니다. 기본 `Destination Root` 는 프로젝트 루트이지만, `Browse` 를 클릭해 다른 폴더를 선택할 수도 있습니다.

![](../assets/copy_skill.jpg)

사용하는 Agent 도구에 맞는 대상을 선택하세요.

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode 및 기타 `AGENTS.md` 호환 Agent 도구: `.agents/skills/ue-widget-creator/`
- Claude Code: `.claude/skills/ue-widget-creator/`

GitHub 에서 ZIP 파일을 직접 다운로드하고 압축을 푼 뒤, `ue-widget-creator` 디렉터리를 해당 `skills` 디렉터리로 복사할 수도 있습니다.

![](../assets/github_skill.jpg)

팀원과 자동화 환경이 동일한 워크플로 지침을 공유할 수 있도록, 프로젝트 리포지토리 안에 두는 것을 권장합니다.

## 디렉터리 구조

일반적인 구조는 다음과 같습니다.

```text
.agents/
  skills/
    ue-widget-creator/
      SKILL.md
      references/
      scripts/
```

## 적합한 사용 사례

적합한 경우:

- 텍스트 요구사항, 디자인 목업, 스케치를 기반으로 UMG UI 생성
- 디자인 이미지나 문서화된 사양을 기반으로 `.widgetdsl` 작성
- 기존 `.widgetdsl` 수정
- 지원되는 위젯을 위한 애니메이션 트랙 생성 또는 편집
- 가져오기 전에 특정 위젯, 프로퍼티, 애니메이션 트랙이 지원되는지 확인
- DSL 파일을 일괄 검증하고 Widget Blueprint 로 가져오기

적합하지 않은 경우:

- Event Graph 생성
- 런타임 바인딩 또는 델리게이트
- 현재 지원 범위를 벗어난 임의의 커스텀 위젯

## AI Agent 는 이 skill 을 어떻게 사용해야 하는가

`Claude Code`, `Codex`, `Gemini CLI` 중 무엇을 사용하든 핵심 요구사항은 같습니다.

- Agent 가 프로젝트 리포지토리에 접근할 수 있어야 함
- Agent 가 로컬 스크립트나 commandlet 을 실행할 수 있어야 함. 다만 명령 실행 권한을 요청할 수 있음

권장 워크플로:

1. 리포지토리 루트를 Agent 작업 디렉터리로 사용
2. Agent 에게 `ue-widget-creator` skill 을 사용하라고 명확히 지시
3. Agent 에게 `.widgetdsl` 생성 또는 수정을 요청
4. Agent 에게 위젯 애니메이션 생성 또는 수정을 요청
5. Agent 에게 먼저 validate / preview 를 실행하도록 요청
6. Agent 에게 DSL을 가져와 Widget Blueprint 를 생성하도록 요청

제 사용 경험상 GPT-5.4+ 모델은 다른 모델보다 UI 생성 결과가 더 좋습니다. 다른 모델로 원하는 결과가 나오지 않는다면 GPT-5.4+ 를 시도해 보세요.

### 예시

```shell
cd /path/to/your/project
codex
$ue-widget-creator Create a full-screen inventory widget with a 4x7 item slot grid on the left and an item details panel on the right.
```

다른 Agent 도구를 사용하더라도 같은 방식으로 접근하면 됩니다. 먼저 `ue-widget-creator` 를 사용해야 한다고 명확히 말한 뒤, UI 설명, 레이아웃 요구사항, 애니메이션이나 Blueprint 가져오기가 필요한지 여부를 제공하세요.

## 출력

일반적인 출력은 다음과 같습니다.

- DSL 파일: `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl`
- 애니메이션이 포함된 DSL 파일: 동일하게 `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl` 에 저장
- 미리보기 이미지: `Saved/WidgetDSLPreview/.../*.png`
- 가져온 Blueprint: 프로젝트 내부의 `/Game/.../WBP_*`

## 에디터 패널 가이드

플러그인을 활성화한 뒤, 메인 패널은 다음 위치에서 열 수 있습니다.

- 메인 메뉴: `AIBridge` -> `Widget Semantic Bridge`

기존 Widget Blueprint 하나만 DSL로 내보내고 싶다면, Content Browser 에서 Widget Blueprint 를 우클릭한 뒤 `Export To Widget DSL` 을 사용할 수도 있습니다.

![Widget Semantic Bridge 패널](../assets/widget_panel.jpg)

패널은 주로 세 부분으로 나뉩니다.

### 1. Batch Export / Batch Import

상단의 두 버튼은 프로젝트 전체를 대상으로 하는 일괄 작업용입니다.

- `Export All WBPs`: `/Game` 아래의 Widget Blueprint 를 `<Project>/.ue_dsl/WidgetDSL` 로 일괄 내보내며, 원래의 `/Game` 하위 폴더 구조를 유지합니다
- `Import New/Changed DSLs`: `<Project>/.ue_dsl/WidgetDSL` 에서 DSL 파일을 일괄 가져오며, 새 파일 또는 현재 Blueprint 내보내기보다 더 최신이고 내용이 다른 DSL 파일만 처리합니다

팀 워크플로, 일괄 동기화, 또는 AI가 이미 여러 `.widgetdsl` 파일을 생성한 경우에 유용합니다.

### 2. 단일 파일 가져오기: `Import DSL Into Widget Blueprint`

하나의 `.widgetdsl` 을 Unreal 의 Widget Blueprint 로 가져옵니다.

- `DSL File` 에서 대상 파일을 선택하고, 먼저 `Validate` 를 클릭하는 것을 권장합니다
- `Target WBP` 에는 가져오기 대상이 자동으로 표시됩니다
- 모든 것이 올바른지 확인한 뒤 `Import DSL` 을 클릭합니다

참고: DSL 파일은 `<Project>/.ue_dsl/WidgetDSL` 아래에 있어야 합니다. 그렇지 않으면 패널이 대상 Blueprint 경로를 자동으로 매핑할 수 없습니다.

### 3. 단일 파일 내보내기: `Export Widget Blueprint To DSL`

기존 Widget Blueprint 를 `.widgetdsl` 로 다시 내보냅니다.

- `Widget Blueprint` 에서 `/Game` 아래의 대상 애셋을 선택합니다
- `Output DSL File` 에 출력 경로가 자동으로 표시됩니다
- `Export DSL` 을 클릭해 내보내기를 실행합니다

UMG에서 UI를 수동으로 조정한 뒤, 그 결과를 DSL로 다시 동기화하여 AI가 이어서 수정하게 하거나 버전 관리에 포함하고 싶을 때 유용합니다.
