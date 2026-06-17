# ue-material-creator 가이드

[English](ue-material-creator.en.md) | [中文](ue-material-creator.cn.md) | [日本語](ue-material-creator.ja.md) | 한국어

이 문서는 `ue-material-creator` skill과 `MaterialSemanticBridge` 플러그인을 함께 사용해 AI Agent가 Unreal 머티리얼 DSL을 생성, 검증, 정규화, 미리보기, 수정, 가져오기, 내보내기하는 방법을 설명합니다.

![](../assets/material_cover.png)

## 개요

`ue-material-creator`는 AI Agent용 워크플로 skill입니다.

Unreal 런타임 코드도 아니고 독립 플러그인도 아닙니다. 목적은 AI Agent가 다음 작업을 수행하도록 안내하는 것입니다.

- 머티리얼 시각 요구사항을 분석하고 `Material` 또는 `MaterialInstanceConstant` 워크플로를 선택합니다
- 지원되는 들여쓰기 형식의 `.materialdsl`을 생성하거나 편집합니다
- 문서화된 `MaterialExpression*`, 속성, pin, 머티리얼 설정, 그래프 레이아웃, 머티리얼 출력 지원 범위 안에서 작업합니다
- 가져오기 전에 DSL을 검증하고 정규화합니다
- 정규화 흐름에서 생성된 머티리얼 미리보기 이미지와 보고서를 읽고, AI Agent가 시각적으로 자체 평가한 뒤 `.materialdsl`을 수정합니다
- 안정화된 DSL을 `Material` 또는 `MaterialInstanceConstant` 애셋으로 가져옵니다
- 기존 머티리얼 또는 머티리얼 인스턴스를 DSL로 다시 내보내 AI가 계속 반복 작업할 수 있게 합니다

## MaterialSemanticBridge와의 관계

이 구성은 두 부분으로 이루어져 있습니다.

- `MaterialSemanticBridge`: 검증, 정규화, 미리보기 이미지와 보고서 생성, 가져오기, 내보내기, schema 탐색, 에디터 통합을 담당하는 Unreal Editor 플러그인
- `ue-material-creator`: 요구사항 분석, DSL 생성, 미리보기 평가, 수정 워크플로를 담당하는 AI Agent skill

플러그인이 Unreal 쪽 작업을 실행하고, skill은 Agent가 DSL을 작성하고 확인하며 미리보기를 평가하고 수정하는 방법을 안내합니다.

## 게임 개발 생산성 향상 가치

게임 프로젝트에서 머티리얼은 아트 방향, 레벨 환경, 성능 예산, 게임플레이 피드백에 맞춰 계속 반복 수정됩니다. `MaterialSemanticBridge` 플러그인과 `ue-material-creator`를 함께 사용하면 “머티리얼 요구사항 설명 -> DSL 생성 -> 검증 / 정규화 -> 미리보기 이미지 생성 -> AI 시각 평가 및 수정 -> Unreal 애셋으로 가져오기” 흐름을 반복 가능한 워크플로로 만들 수 있어, 노드를 손으로 구성하고 파라미터를 조정하며 머티리얼 변형을 정리하는 시간을 줄일 수 있습니다.

일반적인 직접 효과는 다음과 같습니다.

- UI, 지형, 돌, 금속, 천, VFX 베이스 머티리얼 같은 시각 방향을 더 빠르게 프로토타입할 수 있습니다
- 머티리얼 시각 메모, 노드 그래프 설명, 텍스트 요구사항을 가져올 수 있는 `Material` / `MaterialInstanceConstant` 애셋으로 더 빠르게 전환하여, 아이디어와 에디터 애셋 사이의 정보 손실을 줄일 수 있습니다
- 머티리얼 인스턴스 파라미터가 `.materialdsl` 텍스트로 표현되므로, AI가 같은 부모 머티리얼 아래에서 색상, 러프니스, 텍스처, static switch 같은 변형을 일괄 생성하거나 조정하기 쉽습니다
- 정규화 흐름은 머티리얼 미리보기 이미지를 생성할 수 있습니다. 동적 머티리얼은 여러 프레임의 미리보기도 출력할 수 있어, 움직임, 깜박임, 패닝, 펄스 효과가 기대에 맞는지 AI가 확인하기 쉽습니다
- 테크니컬 아티스트가 아니더라도 이 skill과 플러그인을 사용해 요구사항에 더 가까운 머티리얼 효과를 만들 수 있습니다
- 기존 머티리얼이나 머티리얼 인스턴스를 일괄 내보낸 뒤에는 AI가 빈 그래프를 추측하는 대신 프로젝트의 실제 애셋을 기준으로 계속 편집할 수 있습니다
- 머티리얼 DSL은 버전 관리와 코드 리뷰 흐름에 올리기 좋아, 테크니컬 아티스트, 프로그래머, AI Agent가 같은 읽기 쉬운 텍스트를 중심으로 협업할 수 있습니다
- 반복적인 머티리얼 구성, 변형 생성, 동기화 작업을 플러그인과 skill에 맡기면 개발자는 아트 판단, 성능 절충, 런타임 표현에 더 많은 시간을 쓸 수 있습니다

## 설치

### 1. 플러그인 설치

플러그인 주소: [MaterialSemanticBridge](https://www.fab.com/listings/cb2fcfbe-a4db-4dee-a9cf-8bbe62823418)

플러그인이 Fab에서 제공되는 경우 보통 `Install to Engine`으로 Unreal Engine 디렉터리에 설치합니다.

`MaterialSemanticBridge`는 두 가지 설치 방식을 지원합니다.

- 프로젝트 플러그인: `<Project>/Plugins/MaterialSemanticBridge`
- 엔진 플러그인: `<Engine>/Plugins/.../MaterialSemanticBridge`

설치 후 Unreal Editor에서 `Edit` -> `Plugins`로 이동해 `MaterialSemanticBridge`를 찾아 활성화합니다.

### 2. skill 배치

Unreal Editor에서 `AIBridge` -> `Material Semantic Bridge`를 연 다음 `Download Agent Skill`을 사용해 skill을 프로젝트에 다운로드합니다. 기본 `Destination Root`는 프로젝트 루트이지만 `Browse`를 클릭해 다른 폴더를 선택할 수도 있습니다.

![](../assets/ue-material-creator-download-skill.png)

사용하는 Agent 도구에 맞는 대상을 유지합니다.

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode 및 기타 `AGENTS.md` 호환 Agent 도구: `.agents/skills/ue-material-creator/`
- Claude Code: `.claude/skills/ue-material-creator/`

[GitHub](https://github.com/jokance/ue-ai-semantic-bridges/tree/main)에서 ZIP 파일을 직접 다운로드하고 압축을 푼 뒤 `skills/ue-material-creator` 디렉터리를 해당 `skills` 디렉터리에 복사할 수도 있습니다.

![](../assets/download-github-skill.png)

팀원과 자동화 환경이 같은 워크플로 지침을 공유할 수 있도록 프로젝트 저장소에 포함하는 것을 권장합니다.

## 디렉터리 구조

일반적인 구조는 다음과 같습니다.

```text
.agents/
  skills/
    ue-material-creator/
      agents/
      references/
      scripts/
      .version
      SKILL.md
```

## 적합한 사용 사례

적합한 경우:

- 새 `.materialdsl` 생성
- 기존 `.materialdsl` 편집
- 머티리얼 시각 메모나 shader graph 설명을 가져올 수 있는 머티리얼 DSL로 변환
- 노드 클래스, 속성, pin, 머티리얼 설정, 출력 지원 여부 확인
- 머티리얼 DSL을 검증, 정규화하고 미리보기 이미지를 생성한 뒤, 미리보기 결과에 따라 수정
- 기존 머티리얼 또는 머티리얼 인스턴스를 DSL로 내보내 AI 편집에 사용
- `/Game` 아래의 머티리얼 DSL을 일괄 내보내거나, 새로 만들거나 업데이트된 DSL 파일만 가져오기

적합하지 않은 경우:

- 런타임 머티리얼 인스턴스 파라미터 변경
- 지원 범위 밖의 임의 HLSL. DSL에는 지원되는 `MaterialExpressionCustom` 사용만 넣는 것이 적합합니다
- Niagara, UMG, Blueprint, Sequencer, MetaSound DSL
- 관련 없는 Unreal C++ 변경

## AI Agent 사용 방법

권장 워크플로:

1. 저장소 루트를 Agent 작업 디렉터리로 사용합니다.
2. Agent에게 `ue-material-creator` skill을 사용하라고 명시합니다.
3. `.materialdsl` 생성 또는 수정을 요청합니다.
4. Agent에게 정규화 흐름을 실행하게 합니다. 이 흐름은 먼저 DSL을 검증하고, 성공하면 정규화된 DSL을 생성하며, 렌더링을 사용할 수 있을 때 머티리얼 미리보기 이미지를 출력합니다.
5. Agent가 미리보기 이미지 또는 여러 프레임 미리보기를 읽고 요구사항에 비추어 머티리얼 효과를 자체 평가하게 합니다. 시각 결과가 기대와 다르면 DSL을 수정한 뒤 다시 정규화합니다.
6. DSL과 미리보기 효과가 모두 통과하면 안정화된 DSL을 Unreal로 가져오게 합니다.

예시(Codex):

1. `$` 기호로 `UE Material Creator` skill을 선택합니다(Codex 작업 디렉터리 아래에 해당 skill이 올바르게 배치되어 있는지 확인). 선택한 뒤 Enter를 누릅니다.
![](../assets/codex-app-material-example.png)
2. 원하는 머티리얼 생성 또는 수정 요구사항을 입력합니다.
![alt text](../assets/codex-app-material-example-2.png)
3. 나머지 작업은 AI에게 맡깁니다.  
![alt text](../assets/codex-app-material-example-3.png)

다른 Agent 도구를 사용하는 경우에도 같은 방식으로 요청하면 됩니다. 먼저 `ue-material-creator`를 사용하라고 명시하고, 그다음 머티리얼 설명, 머티리얼 미리보기 생성 여부 또는 DSL을 Unreal 애셋으로 가져올지 여부를 전달합니다.

## 출력

일반적인 출력:

- DSL 파일: `.ue_dsl/MaterialDSL/.../*.materialdsl`
- 가져온 머티리얼: `/Game/.../M_*`
- 가져온 머티리얼 인스턴스: `/Game/.../MI_*`
- 정규화, 검증, 가져오기, 내보내기 보고서
- 머티리얼 미리보기 PNG: `Saved/MaterialSemanticBridge/MaterialDSLPreview/...`

정적 머티리얼은 보통 한 장의 미리보기 이미지를 출력합니다. 시간 기반 표현식이 포함된 동적 머티리얼은 여러 프레임의 미리보기를 출력할 수 있습니다.

## 에디터 패널

플러그인을 활성화한 뒤 메인 패널은 다음 위치에서 열 수 있습니다.

- 메인 메뉴: `AIBridge` -> `Material Semantic Bridge`

패널은 통합 라우팅을 사용합니다.

- `Export All DSLs`: `/Game` 아래의 `MaterialInstanceConstant`와 지원되는 `Material` 그래프를 내보내고 `/Game` 하위 디렉터리 구조를 유지합니다
- `Import New/Changed DSLs`: 새로 만들거나 업데이트된 DSL 파일을 가져오고 DSL 타입에 맞는 대상 애셋으로 라우팅합니다
- `Import DSL`: 단일 `.materialdsl`을 검증하고 자동 매핑된 대상 애셋으로 가져옵니다
- `Export DSL`: 선택한 `Material` 또는 `MaterialInstanceConstant`를 매핑된 `.materialdsl`로 내보냅니다

단일 파일과 배치 워크플로 모두 사용자가 “머티리얼 인스턴스” 또는 “머티리얼 그래프”를 직접 고를 필요가 없습니다. 플러그인이 DSL 내용 또는 선택된 애셋 타입에 따라 자동으로 라우팅합니다.
