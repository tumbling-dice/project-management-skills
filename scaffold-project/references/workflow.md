# 立ち上げワークフロー

立ち上げ時に、どの文書をどの順でscaffoldするか決めるときに使う。

## 文書分類

- `docs/spec/`: 長期保存する仕様根拠。PJ目的、要件、architecture、画面責務、判断ログを置く。
- `docs/contract/`: 長期保存する作業契約。AI利用ルール、検証コマンド、review条件、workflow map、安全境界を置く。
- `docs/work/`: 短命な作業コンテクスト。人間が読む `<task-id>.md` と、workflow用の `<task-id>.state.json` を1ペアで使う。作業完了後は仕様根拠または作業契約へバックポートすべき内容だけ残す。

## 標準セッションの形

1. PJの状態を確認する:
   - 何を作るのか
   - 誰が使うのか
   - 最初に価値が出る範囲はどこか
   - 明示的な非対象範囲は何か
   - AIエージェントに触らせてはいけない環境、データ、操作は何か
2. 詳細な仕様根拠より先に、暫定AI利用メモを `docs/contract/` へ作る。
3. PJ Charterを `docs/spec/` へ下書きする。
4. Charterを元にRequirementsを下書きし、不明点は見える場所に残す。
5. 技術嗜好だけでなくRequirementsからArchitectureメモを作る。
6. PJ境界とAI利用境界が見えてから `AGENTS.md` を下書きする。
7. 最初の小さなタスク用に、work-context template、work-state template、reviewable-gateを作る。
8. PJの状態に応じて、検証コマンド、review routing、decision log、workflow map、screen catalogを追加する。

## 最小文書セット

ユーザーが一通りの初稿を求めた場合は、このセットを使う:

```text
docs/contract/ai-usage-note.md
docs/spec/pj-charter.md
docs/spec/requirements-brief.md
docs/spec/architecture-brief.md
AGENTS.md
docs/work/_template.md
docs/contract/reviewable-gate.md
```

repoに既存の文書配置がある場合は、意図を保ったままpathを合わせる。

## 状況に応じた追加文書

- AIまたはtest_runnerに主要フロー、権限、tenant、表示、ログのsmoke testを実行または委譲させるPJ: `docs/contract/smoke-test.md`
- 検証コマンドが分かっている既存repo: `docs/contract/verification-commands.md`
- 認証、権限、PII、DB migration、release操作、外部serviceがあるPJ: `docs/contract/review-routing.md`
- 技術選定、MVP範囲、データ保持、認証方式、外部service選定を残したいPJ: `docs/spec/decision-log.md`
- AI coding agentを継続的に使うPJ: `docs/contract/workflow-map.md`
- Web app、mobile app、desktop app、管理画面、UI-heavy tool: `docs/spec/screen-catalog.md`
- AIにUI実装、修正、visual pass準備を任せるPJ: `docs/contract/ui-implementation-rules.md`
- visual baseline、screenshot baseline、デザインレビューを早期に使うPJ: 対象画面ごとの `docs/spec/screens/<screen-id>.md`
- UIの共通token、theme color、component使用条件を固定したいPJ: `docs/spec/design-system.md`

`screen-catalog.md` は画面索引であり、全画面の詳細仕様を集約しない。
`screen-spec.md` の雛形は、対象画面ごとに `docs/spec/screens/<screen-id>.md` として使う。`wf-explore` は対象画面とscreen spec pathを作業コンテクストへ記録し、実装時はその記録に含まれるscreen specだけを読む。
`design-system.md` は完全なブランドガイドの代替ではなく、UIが満たす共通token、theme、component使用条件に絞る。AI coding agentが実装時に守る禁止事項や確認手順は `ui-implementation-rules.md` へ置く。画面固有の例外やscreenshot却下条件は対象画面のscreen specへ置く。

`environment-boundaries.md` は独立文書にせず、通常は `docs/contract/ai-usage-note.md` へ含める。長い作業のhandoffは、startup文書ではなく `handoff` を優先する。

`docs/work/<task-id>.md` と `docs/work/<task-id>.state.json` は長期保存する仕様根拠や作業契約ではない。Markdownは人間が読む判断、計画、レビュー観点を置き、state fileはworkflow status、進捗、対象ファイル、関連ファイル、コマンドと結果、Markdownへの参照だけを置く。方針、判断理由、調査メモはstate fileへ書かない。作業完了後は、残すべき内容だけ `docs/spec/` または `docs/contract/` へバックポートし、個別作業コンテクストは削除してよい。ローカル作業だけで使うPJでは、次を `.gitignore` の候補にする。

```gitignore
docs/work/*
!docs/work/_template.md
!docs/work/_template.state.json
!docs/work/README.md
```

## 確認質問

文書内容が実際に変わる質問だけをする:

- 主なユーザーまたは運用者は誰か
- 最初のMVPで達成したい結果は何か
- 初回では変更してはいけないものは何か
- AI利用を禁止するデータや環境は何か
- build、test、lint、typecheck、local verificationに使える安全なコマンドは何か
- review ownerや専門reviewが必要になる変更種別は何か
- 初期判断として残すべき技術選定、MVP範囲、データ保持、外部service選定は何か
- UIを持つ場合、初期に責務を固定したい画面やrouteは何か
- GitHub、別のチケットシステム、Markdown作業コンテクストのどれを使うか

## 完了報告

完了時は次を報告する:

- 作成または更新したファイル
- 仕様根拠、作業契約、短命な作業コンテクストtemplateの分類
- 仮説として記録した前提
- `要確認` のまま残した判断
- 最初に試す小さなタスク候補
- 意図的に後回しにした文書
