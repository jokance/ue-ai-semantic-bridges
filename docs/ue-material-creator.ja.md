# ue-material-creator ガイド

[English](ue-material-creator.en.md) | [中文](ue-material-creator.cn.md) | 日本語 | [한국어](ue-material-creator.ko.md)

このドキュメントでは、`ue-material-creator` skill と `MaterialSemanticBridge` プラグインを組み合わせて、AI Agent が Unreal マテリアル DSL を生成、検証、正規化、インポート、エクスポートする方法を説明します。

## 概要

`ue-material-creator` は AI Agent 向けのワークフロー skill です。

Unreal のランタイムコードではなく、単体のプラグインでもありません。目的は AI Agent に次の作業手順を与えることです。

- マテリアル要件を分析する
- サポート済みの `.materialdsl` を生成または編集する
- 正しいマテリアルインスタンス DSL またはマテリアルグラフ DSL を選ぶ
- ドキュメント化された `MaterialExpression*`、プロパティ、マテリアル設定、グラフレイアウト、マテリアル出力の範囲内に収める
- インポート前に DSL を検証、正規化する
- 検証済み DSL を `Material` または `MaterialInstanceConstant` アセットにインポートする

## MaterialSemanticBridge との関係

この構成は 2 つの部分で成り立ちます。

- `MaterialSemanticBridge`: 検証、インポート、エクスポート、エディタ連携を担当する Unreal Editor プラグイン
- `ue-material-creator`: 要件分析と DSL 生成ワークフローを担当する AI Agent skill

プラグインが処理を実行し、skill が Agent の DSL 作成と修復の手順を定義します。

## ゲーム開発の効率化における価値

ゲームプロジェクトでは、マテリアルはアートディレクション、レベル環境、パフォーマンス予算、ゲームプレイのフィードバックに合わせて何度も調整されます。`MaterialSemanticBridge` と `ue-material-creator` を組み合わせることで、「マテリアル要件を説明する -> DSL を生成する -> 検証 / 正規化する -> Unreal アセットへインポートする」という流れを再現可能なワークフローにでき、手作業でノードを組む時間、パラメータ調整、マテリアルバリエーション管理の負担を減らせます。

主な利点は次の通りです。

- 地形、石、金属、布、VFX のベースマテリアルなどのプロトタイプをより速く作成できる
- look-dev メモ、shader graph の説明、文章ベースの要件を、インポート可能な `Material` / `MaterialInstanceConstant` アセットに変換しやすくなる
- マテリアルインスタンスのパラメータが `.materialdsl` テキストで表現されるため、AI が同じ親マテリアルの下で色、ラフネス、テクスチャ、静的スイッチなどのバリエーションを一括生成または調整しやすい
- TA ではない人でも、この skill とプラグインを使って目的のマテリアル表現を作成できる
- 既存のマテリアルやマテリアルインスタンスを一括エクスポートすれば、AI は空のグラフを推測するのではなく、プロジェクト内の実アセットを元に編集を続けられる
- マテリアル DSL はバージョン管理やレビューに載せやすく、テクニカルアーティスト、プログラマー、AI Agent が同じ読みやすいテキストを中心に協作できる
- 繰り返しのグラフ作成、バリエーション生成、アセット同期をプラグインと skill に任せることで、開発者はアート判断、パフォーマンス判断、ランタイム表現により多くの時間を使える

## インストール

### 1. プラグインをインストール

`MaterialSemanticBridge` は Unreal Editor プラグインとして配布されます。Fab で公開された後は、Fab のページから `Install to Engine` でインストールできます。

`MaterialSemanticBridge` は次の 2 つのインストール形式をサポートします。

- プロジェクトプラグイン: `<Project>/Plugins/MaterialSemanticBridge`
- エンジンプラグイン: `<Engine>/Plugins/.../MaterialSemanticBridge`

インストール後、Unreal Editor で `Edit` -> `Plugins` を開き、`MaterialSemanticBridge` を有効化してください。

### 2. skill を配置

Unreal Editor で `AIBridge` -> `Material Semantic Bridge` を開き、`Agent Skill Setup` を使って付属 skill をプロジェクトにコピーします。デフォルトの `Destination Root` はプロジェクトルートですが、`Browse` から別のフォルダも選べます。

![](../assets/copy_skill.jpg)

使っている Agent ツールに合わせて配置先を選びます。

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode など `AGENTS.md` 互換の Agent ツール: `.agents/skills/ue-material-creator/`
- Claude Code: `.claude/skills/ue-material-creator/`

公開リリース後は、GitHub から ZIP ファイルを直接ダウンロードし、展開した `ue-material-creator` ディレクトリを対応する `skills` ディレクトリにコピーすることもできます。

![](../assets/github_skill.jpg)

チームメンバーや自動化環境で同じワークフロー説明を共有できるよう、プロジェクトリポジトリに含めておくことを推奨します。

## ディレクトリ構成

典型的な構成は次の通りです。

```text
.agents/
  skills/
    ue-material-creator/
      SKILL.md
      references/
```

## DSL の種類

マテリアルインスタンス DSL は `MaterialInstanceConstant` アセット用です。親マテリアルとサポート済みパラメータのオーバーライドを記述します。

```text
schema 1
material_instance "MI_Stone_Wet"
parent_material "/Game/Materials/M_Stone.M_Stone"

scalar_param Roughness "0.18"
vector_param Tint "(R=0.45,G=0.52,B=0.58,A=1)"
texture_param BaseColorTexture "/Game/Textures/T_Stone_D.T_Stone_D"
static_switch_param UseWetLayer "true"
```

マテリアルグラフ DSL は `Material` アセット用です。グラフノード、プロパティ、接続、出力、グラフレイアウトを記述します。

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

Material Result ノードのエディタ上の位置を明確にし、生成ノードとの重なりを避けたい場合は `set graph.result_pos "X,Y"` を使います。

## 適した用途

適した用途:

- 新しい `.materialdsl` の作成
- 既存 `.materialdsl` の編集
- look-dev メモや shader graph 説明をインポート可能なマテリアル DSL に変換する
- ノードクラス、プロパティ、pin、マテリアル設定、出力がサポートされているか確認する
- マテリアル DSL を検証、正規化、インポートする
- 既存のサポート済みマテリアルまたはマテリアルインスタンスを DSL にエクスポートし、AI 編集に戻す

適さない用途:

- ランタイムのマテリアルインスタンスパラメータ変更
- サポート範囲外の任意 HLSL
- Niagara、UMG、Blueprint、Sequencer、MetaSound DSL
- 無関係な Unreal C++ 変更

## AI Agent での使い方

推奨ワークフロー:

1. リポジトリルートを Agent の作業ディレクトリにする。
2. `ue-material-creator` skill を使うよう Agent に明示する。
3. `.materialdsl` の生成または変更を依頼する。
4. DSL の検証または正規化を依頼する。
5. 検証済み DSL を対応する `/Game` アセットにインポートする。

例:

```shell
cd /path/to/your/project
codex
$ue-material-creator Create a material graph DSL for a wet stone surface with a tinted base color and roughness output.
```

## 出力

主な出力:

- DSL ファイル: `.ue_dsl/MaterialDSL/.../*.materialdsl`
- インポートされたマテリアル: `/Game/.../M_*`
- インポートされたマテリアルインスタンス: `/Game/.../MI_*`
- commandlet ワークフローで生成される検証またはインポートレポート

## エディタパネル

プラグインを有効化した後、メインパネルは次から開けます。

- メインメニュー: `AIBridge` -> `Material Semantic Bridge`

パネルは統一ルーティングを使います。

- `Export All DSLs`: `/Game` 以下の `MaterialInstanceConstant` とサポート済み `Material` グラフをエクスポートする
- `Import New/Changed DSLs`: 新規または更新された DSL ファイルをインポートし、DSL 種別に応じて処理を分ける
- `Import DSL`: 単一の `.materialdsl` を検証し、自動マッピングされた対象アセットにインポートする
- `Export DSL`: 選択した `Material` または `MaterialInstanceConstant` を対応する `.materialdsl` にエクスポートする

単一ファイルでもバッチでも、ユーザーが「マテリアルインスタンス」か「マテリアルグラフ」かを手動で選ぶ必要はありません。プラグインが DSL の内容または選択されたアセット種別から自動で分岐します。
