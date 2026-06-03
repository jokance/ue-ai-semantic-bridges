# AI Agent Skills

[English](../README.md) | [中文](README.cn.md) | [日本語](README.ja.md) | 한국어

이 디렉터리에는 프로젝트 도구와 워크플로와 함께 사용하는 저장소 로컬 AI Agent skills가 들어 있습니다.

## 사용 가능한 Skills

### `ue-widget-creator`

`ue-widget-creator`는 `WidgetSemanticBridge`용 skill 워크플로입니다.

AI Agent가 다음 작업을 수행하는 데 사용합니다.

- UMG UI 요구사항 분석
- 요구사항을 지원되는 `.widgetdsl`로 변환
- 문서화된 위젯과 속성 지원 범위 안에서 생성 유지
- 가져오기 전에 생성된 DSL 검증
- 검증된 DSL을 Unreal Widget Blueprints로 가져오기

이 skill은 에디터 제작 워크플로용이며 런타임 로직 생성용이 아닙니다.

- [쇼케이스](https://www.youtube.com/watch?v=OsDRfoziQg8)
- [가이드](ue-widget-creator.ko.md)

### `ue-material-creator` (곧 공개 예정)

`ue-material-creator`는 `MaterialSemanticBridge`용 skill 워크플로입니다.

AI Agent가 다음 작업을 수행하는 데 사용합니다.

- Unreal 머티리얼 요구사항 분석
- 지원되는 `.materialdsl` 생성 또는 편집
- DSL 내용과 대상 애셋 타입에 따라 머티리얼 인스턴스 DSL과 머티리얼 그래프 DSL 구분
- 문서화된 `MaterialExpression*`, 속성, 머티리얼 설정, 그래프 레이아웃, 출력 지원 범위 안에서 생성 유지
- `set graph.result_pos "X,Y"`로 Material Result 노드 위치를 지정하는 것을 포함해 머티리얼 그래프 노드를 명확하게 배치
- 가져오기 전에 생성된 DSL 검증
- 검증된 DSL을 Unreal `Material` 또는 `MaterialInstanceConstant` 애셋으로 가져오기

이 skill은 에디터 제작 워크플로용이며 런타임 머티리얼 인스턴스 파라미터 변경이나 관련 없는 Unreal C++ 작업용이 아닙니다.

- [가이드](ue-material-creator.ko.md)

## 커뮤니티

- [Discord](https://discord.gg/gbbPGeVXw9)
