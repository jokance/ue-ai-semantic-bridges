# ue-widget-creator ガイド

このドキュメントでは、`ue-widget-creator` skill と `WidgetSemanticBridge` プラグインを組み合わせて、AI Agent が静的 UI、ウィジェットアニメーション DSL を生成し、検証、プレビュー、UMG Widget Blueprint へのインポートまで行う方法を説明します。

![カバー](../assets/cover_main.jpg)

## これは何か

`ue-widget-creator` は AI Agent 向けのワークフロー skill です。

これは Unreal のランタイムコードではなく、単体のプラグインでもありません。目的は、AI Agent に次の作業を行わせるための指針を与えることです。

- UI 要件を分析する
- 要件をサポート済みの `.widgetdsl` に変換する
- 生成範囲を `WidgetSemanticBridge` がサポートするウィジェット、プロパティ、Slot、アニメーショントラックの範囲内に制限する
- `animation` / `track` セクションを生成または修正する
- インポート前に検証とプレビューを実行する
- 検証済み DSL を Unreal 内の実際の `WBP_*` としてインポートする

## WidgetSemanticBridge との関係

この構成は 2 つの要素で成り立っています。

- `WidgetSemanticBridge`: 検証、プレビュー、インポートを担当する [Unreal Editor プラグイン](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f)
- `ue-widget-creator`: 要件分析と DSL 生成ワークフローを担当する AI Agent skill

プラグインが実行を担当し、skill がワークフローを担当します。

## ゲーム開発の効率化における価値

ゲームプロジェクトでは、UI はゲームプレイ、数値、グラフィックデザインのフィードバックに合わせて何度も調整されます。`WidgetSemanticBridge` プラグインと `ue-widget-creator` を組み合わせることで、「要件を説明する -> DSL を生成する -> 検証 / プレビューする -> Blueprint にインポートする」という流れを再現可能なワークフローにでき、手作業で UI を組んだりエディタを何度もクリックしたりする時間を大きく減らせます。

主な利点は次の通りです。

- インベントリ、メインメニュー、クエストパネル、ポップアップなどの機能画面の UI プロトタイプをより速く作成できる
- デザイン稿、スケッチ、文章説明を、インポート可能な Widget Blueprint により速く落とし込め、実装経路での情報損失を減らせる
- 画面レイアウトと一部のアニメーションが `.widgetdsl` テキスト形式で表現されるため、AI が対応する UI 記述を理解、生成、修正しやすくなり、UI インタラクション、状態切り替え、フロー調整の反復速度を高められる
- 生成または再エクスポートされた DSL は、AI に UI ロジックを書かせるためにも直接渡せる。WBP 変更後に再度 DSL をエクスポートすれば、AI は最新の UI に合わせてロジックコードを調整でき、通常は UI コードを 1 行ずつ手書きする必要がなくなる。この使い方は、大量の UI ロジックを C++ や Blueprint で書くよりも、Lua、TypeScript、Python などのスクリプト言語と組み合わせる方が推奨される
- インポート前に検証とプレビューを行うことで、未対応のウィジェット、プロパティ、レイアウト問題をより早く発見でき、手戻りコストを下げられる
- `.widgetdsl` の一括生成や一括修正は、チーム協業や自動化フローに適しており、UI アセットをバージョン管理に載せやすい
- UI の構造的な作業をプラグインと skill に任せることで、開発者はゲームプレイロジック、インタラクションの細部、ランタイム挙動の実装により多くの時間を使える

## インストール

### 1. プラグインをインストールする

プラグインリンク: [WidgetSemanticBridge](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f)

プラグインを Fab から入手する場合、通常は `Install to Engine` で Unreal Engine ディレクトリにインストールします。


`WidgetSemanticBridge` は次の 2 つのインストール方式をサポートしています。

- プロジェクトプラグイン: `<Project>/Plugins/WidgetSemanticBridge`
- エンジンプラグイン: `<Engine>/Plugins/.../WidgetSemanticBridge`

インストール後、プロジェクトでプラグインを有効化します。Unreal Editor で `Edit` -> `Plugins` を開き、`WidgetSemanticBridge` を見つけて有効にしてください。

### 2. skill を配置する

Unreal Editor で `AIBridge` -> `Widget Semantic Bridge` を開き、`Download Agent Skill` を使って skill をプロジェクトにダウンロードします。デフォルトの `Destination Root` はプロジェクトルートですが、`Browse` をクリックして別のフォルダを選択することもできます。

![](../assets/ue-widget-creator-download-skill.png)

使用する Agent ツールに合わせて対象を選択してください。

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode、およびその他の `AGENTS.md` 互換 Agent ツール: `.agents/skills/ue-widget-creator/`
- Claude Code: `.claude/skills/ue-widget-creator/`

[GitHub](https://github.com/jokance/ue-ai-semantic-bridges/tree/main) から ZIP ファイルを直接ダウンロードし、展開したあと、`skills/ue-widget-creator` ディレクトリを対応する `skills` ディレクトリへコピーすることもできます。

![](../assets/download-github-skill.png)

チームメンバーや自動化環境が同じワークフロー指示を共有できるよう、プロジェクトリポジトリ内に置くことを推奨します。

## ディレクトリ構成

典型的な構成は次のようになります。

```text
.agents/
  skills/
    ue-widget-creator/
      agents/
      references/
      scripts/
      .version
      SKILL.md
```

## 適したユースケース

適している用途:

- テキスト、デザイン稿、スケッチなどの要件から UMG UI を生成する
- デザイン画像や説明をもとに `.widgetdsl` を補完して書く
- 既存の `.widgetdsl` を修正する
- サポート済みウィジェット向けにアニメーショントラックを生成または修正する
- インポート前に、ウィジェット、プロパティ、アニメーショントラックがサポートされているか確認する
- DSL を一括で検証し、Widget Blueprint としてインポートする

適していない用途:

- Event Graph ロジック生成
- ランタイム Binding または Delegate
- サポート範囲外にある任意のカスタムウィジェット

## AI Agent はこの skill をどう使うべきか

推奨ワークフロー:

1. リポジトリルートを Agent の作業ディレクトリにする
2. Agent に `ue-widget-creator` skill を使うよう明示する
3. Agent に `.widgetdsl` の生成または修正を依頼する
4. Agent にウィジェットアニメーションの生成または修正を依頼する
5. Agent に先に validate / preview を実行させる
6. Agent に DSL をインポートさせ、Widget Blueprint を生成させる


私の経験では、GPT-5.4+ モデルは他のモデルよりも優れた UI 生成結果を出しやすいです。他のモデルで期待する結果が得られない場合は、GPT-5.4+ を試してください。

### 例

```shell
cd /path/to/your/project
codex
$ue-widget-creator Create a full-screen inventory widget with a 4x7 item slot grid on the left and an item details panel on the right.
```

別の Agent ツールを使う場合も考え方は同じです。まず `ue-widget-creator` を使うことを明確に伝え、その後に UI の説明、レイアウト要件、アニメーションや Blueprint インポートが必要かどうかを指定します。

## 出力

一般的な出力は次のとおりです。

- DSL ファイル: `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl`
- アニメーション付き DSL ファイル: 同じく `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl` に保存されます
- プレビュー画像: `Saved/WidgetDSLPreview/.../*.png`
- インポート済み Blueprint: プロジェクトの `/Game/.../WBP_*`

## エディタパネルガイド

プラグインを有効化した後、メインパネルは次から開けます。

- メインメニュー: `AIBridge` -> `Widget Semantic Bridge`

既存の Widget Blueprint を 1 つだけ DSL にエクスポートしたい場合は、Content Browser で Widget Blueprint を右クリックし、`Export To Widget DSL` を使用することもできます。

![Widget Semantic Bridge パネル](../assets/widget_panel.jpg)

このパネルは主に 4 つの部分に分かれています。

### 1. Batch Export / Batch Import

上部の 2 つのボタンは、プロジェクト全体を対象にした一括操作用です。

- `Export All WBPs`: `/Game` 配下の Widget Blueprint を `<Project>/.ue_dsl/WidgetDSL` に一括エクスポートし、元の `/Game` 以下のサブフォルダ構成を保持します
- `Import New/Changed DSLs`: `<Project>/.ue_dsl/WidgetDSL` から DSL を一括インポートし、「新規ファイル」または「現在の Blueprint より新しく、内容に変更がある」DSL だけを処理します

これは、チーム協業、一括同期、または AI がすでに複数の `.widgetdsl` ファイルを生成している場合に便利です。

### 2. 単一ファイルインポート: `Import DSL Into Widget Blueprint`

1 つの `.widgetdsl` を Unreal の Widget Blueprint としてインポートします。

- `DSL File` で対象ファイルを選択します。先に `Validate` をクリックすることを推奨します
- `Target WBP` にはインポート先が自動的に表示されます
- すべて問題ないことを確認したら、`Import DSL` をクリックします

注意: DSL ファイルは `<Project>/.ue_dsl/WidgetDSL` 配下に置く必要があります。そうでない場合、パネルは対象 Blueprint パスを自動マッピングできません。

### 3. 単一ファイルエクスポート: `Export Widget Blueprint To DSL`

既存の Widget Blueprint を `.widgetdsl` にエクスポートします。

- `Widget Blueprint` で `/Game` 配下の対象アセットを選択します
- `Output DSL File` には出力パスが自動的に表示されます
- `Export DSL` をクリックしてエクスポートを実行します

UMG で UI を手動調整した後、その結果を DSL に同期し、さらに AI に編集させたりバージョン管理に含めたりしたい場合に便利です。
