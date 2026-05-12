# 立ち上げワークフロー

立ち上げ時に、どの文書をどの順でscaffoldするか決めるときに使います。

## 標準セッションの形

1. PJの状態を確認する:
   - 何を作るのか
   - 誰が使うのか
   - 最初に価値が出る範囲はどこか
   - 明示的な非対象範囲は何か
   - AIエージェントに触らせてはいけない環境、データ、操作は何か
2. 詳細なPJ文書より先に、暫定AI利用メモを作る。
3. PJ Charterを下書きする。
4. Charterを元にRequirementsを下書きし、不明点は見える場所に残す。
5. 技術嗜好だけでなくRequirementsからArchitectureメモを作る。
6. PJ境界とAI利用境界が見えてから `AGENTS.md` を下書きする。
7. 最初の小さなタスク用に、work-context、reviewable-gate、smoke-testのtemplateを作る。
8. PJの状態に応じて、検証コマンド、review routing、decision log、workflow map、screen catalogを追加する。

## 最小文書セット

ユーザーが一通りの初稿を求めた場合は、このセットを使う:

```text
docs/ai/ai-usage-note.md
docs/project/pj-charter.md
docs/project/requirements-brief.md
docs/project/architecture-brief.md
AGENTS.md
docs/work/_template.md
docs/review/reviewable-gate.md
docs/verification/smoke-test.md
```

repoに既存の文書配置がある場合は、意図を保ったままpathを合わせる。

## 状況に応じた追加文書

- 検証コマンドが分かっている既存repo: `docs/verification/commands.md`
- 認証、権限、PII、DB migration、release操作、外部serviceがあるPJ: `docs/review/review-routing.md`
- 技術選定、MVP範囲、データ保持、認証方式、外部service選定を残したいPJ: `docs/project/decision-log.md`
- AI coding agentを継続的に使うPJ: `docs/ai/workflow-map.md`
- Web app、mobile app、desktop app、管理画面、UI-heavy tool: `docs/project/screen-catalog.md`
- visual baseline、screenshot baseline、デザインレビューを早期に使うPJ: `docs/project/screen-contract.md`

`screen-contract.md` は画面責務の初期整理ではなく、変えてよい範囲と変えてはいけない状態を固定したい場合だけ作る。

`environment-boundaries.md` は独立文書にせず、通常は `docs/ai/ai-usage-note.md` へ含める。長い作業のhandoffは、startup文書ではなく `handoff` を優先する。

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
- GitHub、別のチケットシステム、Markdown作業メモのどれを使うか

## 完了報告

完了時は次を報告する:

- 作成または更新したファイル
- 仮説として記録した前提
- `要確認` のまま残した判断
- 最初に試す小さなタスク候補
- 意図的に後回しにした文書
