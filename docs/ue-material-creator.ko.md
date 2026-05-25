# ue-material-creator 가이드

[English](ue-material-creator.en.md) | [中文](ue-material-creator.cn.md) | [日本語](ue-material-creator.ja.md) | 한국어

이 문서는 `ue-material-creator` skill과 `MaterialSemanticBridge` 플러그인을 함께 사용해 AI Agent가 Unreal 머티리얼 DSL을 생성, 검증, 정규화, 가져오기, 내보내기하는 방법을 설명합니다.

## 개요

`ue-material-creator`는 AI Agent용 워크플로 skill입니다.

Unreal 런타임 코드도 아니고 독립 플러그인도 아닙니다. 목적은 AI Agent가 다음 작업을 수행하도록 안내하는 것입니다.

- 머티리얼 요구사항 분석
- 지원되는 `.materialdsl` 생성 또는 편집
- 올바른 머티리얼 인스턴스 DSL 또는 머티리얼 그래프 DSL 형식 선택
- 문서화된 `MaterialExpression*`, 속성, 머티리얼 설정, 그래프 레이아웃, 머티리얼 출력 지원 범위 안에서 생성 유지
- 가져오기 전에 DSL 검증 및 정규화
- 검증된 DSL을 `Material` 또는 `MaterialInstanceConstant` 애셋으로 가져오기

## MaterialSemanticBridge와의 관계

이 구성은 두 부분으로 이루어져 있습니다.

- `MaterialSemanticBridge`: 검증, 가져오기, 내보내기, 에디터 통합을 담당하는 Unreal Editor 플러그인
- `ue-material-creator`: 요구사항 분석과 DSL 생성 워크플로를 담당하는 AI Agent skill

플러그인이 작업을 실행하고, skill은 Agent가 DSL을 작성하고 수정하는 방식을 정의합니다.

## 게임 개발 생산성 향상 가치

게임 프로젝트에서 머티리얼은 아트 방향, 레벨 환경, 성능 예산, 게임플레이 피드백에 맞춰 계속 반복 수정됩니다. `MaterialSemanticBridge`와 `ue-material-creator`를 함께 사용하면 “머티리얼 요구사항 설명 -> DSL 생성 -> 검증 / 정규화 -> Unreal 애셋으로 가져오기” 흐름을 반복 가능한 워크플로로 만들 수 있어, 노드를 손으로 구성하고 파라미터를 맞추며 머티리얼 변형을 관리하는 시간을 줄일 수 있습니다.

일반적인 직접 효과는 다음과 같습니다.

- 지형, 돌, 금속, 천, VFX 베이스 머티리얼 같은 표면 프로토타입을 더 빠르게 만들 수 있습니다
- look-dev 메모, shader graph 설명, 텍스트 요구사항을 가져올 수 있는 `Material` / `MaterialInstanceConstant` 애셋으로 더 쉽게 전환할 수 있습니다
- 머티리얼 인스턴스 파라미터가 `.materialdsl` 텍스트로 표현되므로, AI가 같은 부모 머티리얼 아래에서 색상, 러프니스, 텍스처, static switch 같은 변형을 일괄 생성하거나 조정하기 쉽습니다
- TA가 아니더라도 이 skill과 플러그인을 사용해 원하는 머티리얼 효과를 만들 수 있습니다
- 기존 머티리얼이나 머티리얼 인스턴스를 일괄 내보낸 뒤에는 AI가 빈 그래프를 추측하는 대신 프로젝트의 실제 애셋을 기준으로 계속 편집할 수 있습니다
- 머티리얼 DSL은 버전 관리와 리뷰 흐름에 올리기 좋아, 테크니컬 아티스트, 프로그래머, AI Agent가 같은 읽기 쉬운 텍스트를 중심으로 협업할 수 있습니다
- 반복적인 그래프 구성, 변형 생성, 애셋 동기화를 플러그인과 skill에 맡기면 개발자는 아트 판단, 성능 절충, 런타임 표현에 더 많은 시간을 쓸 수 있습니다

## 설치

### 1. 플러그인 설치

`MaterialSemanticBridge`는 Unreal Editor 플러그인으로 배포됩니다. Fab에 공개된 뒤에는 Fab 페이지에서 `Install to Engine`으로 설치할 수 있습니다.

`MaterialSemanticBridge`는 두 가지 설치 방식을 지원합니다.

- 프로젝트 플러그인: `<Project>/Plugins/MaterialSemanticBridge`
- 엔진 플러그인: `<Engine>/Plugins/.../MaterialSemanticBridge`

설치 후 Unreal Editor에서 `Edit` -> `Plugins`로 이동해 `MaterialSemanticBridge`를 찾아 활성화합니다.

### 2. skill 배치

Unreal Editor에서 `AIBridge` -> `Material Semantic Bridge`를 연 다음 `Agent Skill Setup`을 사용해 포함된 skill을 프로젝트에 복사합니다. 기본 `Destination Root`는 프로젝트 루트이지만 `Browse`를 눌러 다른 폴더를 선택할 수도 있습니다.

![](../assets/copy_skill.jpg)

사용하는 Agent 도구에 맞는 대상을 유지합니다.

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode 및 기타 `AGENTS.md` 호환 Agent 도구: `.agents/skills/ue-material-creator/`
- Claude Code: `.claude/skills/ue-material-creator/`

공개 릴리스 후에는 GitHub에서 ZIP 파일을 직접 다운로드하고 압축을 푼 뒤 `ue-material-creator` 디렉터리를 해당 `skills` 디렉터리에 복사할 수도 있습니다.

![](../assets/github_skill.jpg)

팀원과 자동화 환경이 같은 워크플로 지침을 공유할 수 있도록 프로젝트 저장소에 포함하는 것을 권장합니다.

## 디렉터리 구조

일반적인 구조는 다음과 같습니다.

```text
.agents/
  skills/
    ue-material-creator/
      SKILL.md
      references/
```

## DSL 타입

머티리얼 인스턴스 DSL은 `MaterialInstanceConstant` 애셋용입니다. 부모 머티리얼과 지원되는 파라미터 오버라이드를 설명합니다.

```text
schema 1
material_instance "MI_Stone_Wet"
parent_material "/Game/Materials/M_Stone.M_Stone"

scalar_param Roughness "0.18"
vector_param Tint "(R=0.45,G=0.52,B=0.58,A=1)"
texture_param BaseColorTexture "/Game/Textures/T_Stone_D.T_Stone_D"
static_switch_param UseWetLayer "true"
```

머티리얼 그래프 DSL은 `Material` 애셋용입니다. 그래프 노드, 속성, 연결, 출력, 그래프 레이아웃을 설명합니다.

```text
schema 2
asset_type "material"
material "M_SimpleRed"

set graph.result_pos "420,0"

node color MaterialExpressionConstant3Vector pos="-300,0"
set color.Constant "(R=1,G=0.05,B=0.02,A=1)"

node rough MaterialExpressionConstant pos="-300,180"
set rough.R "0.35"

output BaseColor color.rgb
output Roughness rough.r
```

Material Result 노드의 에디터 위치를 명확히 하고 생성된 노드와 겹치지 않게 하려면 `set graph.result_pos "X,Y"`를 사용합니다.

## 적합한 사용 사례

적합한 경우:

- 새 `.materialdsl` 생성
- 기존 `.materialdsl` 편집
- look-dev 메모나 shader graph 설명을 가져올 수 있는 머티리얼 DSL로 변환
- 노드 클래스, 속성, pin, 머티리얼 설정, 출력 지원 여부 확인
- 머티리얼 DSL 검증, 정규화, 가져오기
- 기존의 지원되는 머티리얼 또는 머티리얼 인스턴스를 DSL로 내보내 AI 편집에 사용

적합하지 않은 경우:

- 런타임 머티리얼 인스턴스 파라미터 변경
- 지원 범위 밖의 임의 HLSL
- Niagara, UMG, Blueprint, Sequencer, MetaSound DSL
- 관련 없는 Unreal C++ 변경

## AI Agent 사용 방법

권장 워크플로:

1. 저장소 루트를 Agent 작업 디렉터리로 사용합니다.
2. Agent에게 `ue-material-creator` skill을 사용하라고 명시합니다.
3. `.materialdsl` 생성 또는 수정을 요청합니다.
4. DSL 검증 또는 정규화를 요청합니다.
5. 검증된 DSL을 매핑된 `/Game` 애셋으로 가져오게 합니다.

예시:

```shell
cd /path/to/your/project
codex
$ue-material-creator Create a material graph DSL for a wet stone surface with a tinted base color and roughness output.
```

## 출력

일반적인 출력:

- DSL 파일: `.ue_dsl/MaterialDSL/.../*.materialdsl`
- 가져온 머티리얼: `/Game/.../M_*`
- 가져온 머티리얼 인스턴스: `/Game/.../MI_*`
- commandlet 워크플로에서 생성되는 검증 또는 가져오기 보고서

## 에디터 패널

플러그인을 활성화한 뒤 메인 패널은 다음 위치에서 열 수 있습니다.

- 메인 메뉴: `AIBridge` -> `Material Semantic Bridge`

패널은 통합 라우팅을 사용합니다.

- `Export All DSLs`: `/Game` 아래의 `MaterialInstanceConstant`와 지원되는 `Material` 그래프를 내보냅니다
- `Import New/Changed DSLs`: 새 DSL 또는 업데이트된 DSL 파일을 가져오고 DSL 타입에 따라 분기합니다
- `Import DSL`: 단일 `.materialdsl`을 검증하고 자동 매핑된 대상 애셋으로 가져옵니다
- `Export DSL`: 선택한 `Material` 또는 `MaterialInstanceConstant`를 매핑된 `.materialdsl`로 내보냅니다

단일 파일과 배치 워크플로 모두 사용자가 “머티리얼 인스턴스” 또는 “머티리얼 그래프”를 직접 고를 필요가 없습니다. 플러그인이 DSL 내용 또는 선택된 애셋 타입에 따라 자동으로 라우팅합니다.
