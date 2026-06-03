# AI Agent Skills

[English](../README.md) | [中文](README.cn.md) | 日本語 | [한국어](README.ko.md)

このディレクトリには、プロジェクトのツールとワークフローで使うリポジトリローカルの AI Agent skills が含まれています。

## 利用可能な Skills

### `ue-widget-creator`

`ue-widget-creator` は `WidgetSemanticBridge` 用の skill ワークフローです。

AI Agent が次の作業を行うために使います。

- UMG UI 要件を分析する
- 要件をサポート済みの `.widgetdsl` に変換する
- ドキュメント化されたウィジェットとプロパティのサポート範囲内に収める
- インポート前に生成 DSL を検証する
- 検証済み DSL を Unreal Widget Blueprints にインポートする

この skill はエディタでの制作ワークフロー向けであり、ランタイムロジック生成向けではありません。

- [ショーケース](https://www.youtube.com/watch?v=OsDRfoziQg8)
- [ガイド](ue-widget-creator.ja.md)

### `ue-material-creator`（近日公開予定）

`ue-material-creator` は `MaterialSemanticBridge` 用の skill ワークフローです。

AI Agent が次の作業を行うために使います。

- Unreal マテリアル要件を分析する
- サポート済みの `.materialdsl` を生成または編集する
- DSL の内容とターゲットアセット種別から、マテリアルインスタンス DSL とマテリアルグラフ DSL を判別する
- ドキュメント化された `MaterialExpression*`、プロパティ、マテリアル設定、グラフレイアウト、出力のサポート範囲内に収める
- `set graph.result_pos "X,Y"` による Material Result ノード位置を含め、マテリアルグラフノードを分かりやすく配置する
- インポート前に生成 DSL を検証する
- 検証済み DSL を Unreal の `Material` または `MaterialInstanceConstant` アセットにインポートする

この skill はエディタでの制作ワークフロー向けであり、ランタイムのマテリアルインスタンスパラメータ変更や無関係な Unreal C++ 作業向けではありません。

- [ガイド](ue-material-creator.ja.md)

## コミュニティ

- [Discord](https://discord.gg/gbbPGeVXw9)
