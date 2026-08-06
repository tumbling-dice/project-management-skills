---
name: scaffold-project
description: "新規または文書が薄いPJへ、AGENTS、AI利用ルール、仕様・作業契約、短命な作業context、Reviewable Gate、初期検証文書を作る。通常実装、code review、成熟済みPJの更新には使わない。"
---

# scaffold-project

このskillは、AIコーディングエージェントを使うPJで、最初に必要な文書セットを作るためのものである。最初から完全なガバナンスを作るのではなく、最初の小さなタスクに進むための仕様根拠、作業契約、作業コンテクストの境界を整える。

## 基本姿勢

- コード実装から始めない。
- ユーザーの粗い目的、背景、制約、懸念を起点にする。
- 業務意図、安全境界、非対象範囲を勝手に作らないために必要な質問だけをする。
- 不明点は `要確認` として残し、黙って確定しない。
- `確定事項`、`仮説`、`未決事項` を分ける。
- GitHubは任意扱いにする。ユーザーがGitHub利用を明示しない限り、「チケット / 作業コンテクスト / レビュー説明」として扱う。
- secrets、credential、マスキングしていない顧客データ、本番DB接続情報、本番ログの生データを生成文書に含めない。
- 立ち上げ文書は、最初の1〜2週間で読めて更新できる長さに保つ。
- 文書分類を分ける:
  - `docs/spec/`: 長期保存する仕様根拠。PJ目的、要件、architecture、画面責務、判断ログを置く。
  - `docs/contract/`: 長期保存する作業契約。AI利用ルール、検証コマンド、review条件、workflow map、安全境界を置く。
  - `docs/work/`: 短命な作業コンテクスト。人間が読む `<task-id>.md` と、workflow用の `<task-id>.state.json` を1ペアで扱う。作業完了後は仕様根拠または作業契約へバックポートすべき内容だけ残す。

## 進め方

1. PJの状態を確認する:
   - 新規PJ、AI向け文書がない既存repo、既存文書の更新のどれか
   - 作成対象の文書セット
   - 判明している技術スタックと未決定事項
   - AIに扱わせてはいけないデータや環境
2. 最小文書セットを提案する。初期値は次の通り:
   - `docs/contract/ai-usage-note.md`
   - `docs/spec/pj-charter.md`
   - `docs/spec/requirements-brief.md`
   - `docs/spec/architecture-brief.md`
   - `AGENTS.md`
   - `docs/work/_template.md`
   - `docs/work/_template.state.json`
   - `docs/contract/reviewable-gate.md`
3. PJの状態に応じて追加文書を提案する:
   - AIまたはtest_runnerに主要フロー、権限、tenant、表示、ログのsmoke testを実行または委譲させるPJ: `docs/contract/smoke-test.md`
   - 検証コマンドが分かる既存repo: `docs/contract/verification-commands.md`
   - 認証、権限、PII、DB migration、release操作、外部serviceがあるPJ: `docs/contract/review-routing.md`
   - 技術選定、MVP範囲、データ保持、認証方式、外部service選定を残したいPJ: `docs/spec/decision-log.md`
   - AI coding agentを継続利用するPJ: `docs/contract/workflow-map.md`
   - UIを持つPJ: `docs/spec/screen-catalog.md`
   - AIにUI実装、修正、visual pass準備を任せるPJ: `docs/contract/ui-implementation-rules.md`
   - visual baselineやscreenshot reviewを早期に使うPJ: 対象画面ごとの `docs/spec/screens/<screen-id>.md`
   - UIの共通token、theme color、component使用条件を固定したいPJ: `docs/spec/design-system.md`
4. 不足すると危険な文書や誤解を生む事実だけ、簡潔に確認質問する。
5. 下の関連referenceを読み、対応するtemplateを使って文書を作成または更新する。
6. 最後に次を報告する:
   - 作成または更新した文書
   - 仕様根拠、作業契約、短命な作業コンテクストtemplateの分類
   - `人間が判断する点`
   - `次に小さく試すタスク候補`
   - 作成しなかった文書と理由

## 参照資料

ユーザーが求める文書セットに必要なファイルだけを読む:

- `references/workflow.md`: kickoff全体の流れと文書選択。
- `references/contract/ai-usage-note.md`: 暫定AI利用ルールメモ。
- `references/spec/project-charter.md`: 目的、ユーザー、MVP、非対象範囲、成功条件。
- `references/spec/requirements-brief.md`: ユースケース、業務ルール、権限、データ、E2E候補。
- `references/spec/architecture-brief.md`: 技術、認証、tenant、DB、deploy、ログ方針。
- `references/agent-instructions.md`: `AGENTS.md` 初稿ルール。
- `references/work/work-context.md`: 短命な作業コンテクスト、state file、変更説明の雛形。
- `references/contract/reviewable-gate.md`: レビュー開始条件。
- UIを持つPJでは `references/spec/requirements-brief.md` と `references/workflow.md` を使い、画面責務とvisual review候補を追加文書へ分ける。

## 雛形

文書を作成するときは、`assets/templates/` を転用可能な初期雛形として使う:

- repo root:
  - `AGENTS.md`
- `contract/`:
  - `ai-usage-note.md`
  - `reviewable-gate.md`
  - `verification-commands.md`
  - `review-routing.md`
  - `workflow-map.md`
  - `smoke-test.md`
  - `ui-implementation-rules.md`
- `spec/`:
  - `project-charter.md`
  - `requirements-brief.md`
  - `architecture-brief.md`
  - `decision-log.md`
  - `screen-catalog.md`
  - `screen-spec.md` （対象画面ごとに `docs/spec/screens/<screen-id>.md` として使う）
  - `design-system.md`
- `work/`:
  - `work-context.md`
  - `work-state.json` （`docs/work/_template.state.json` として使う）
  - `change-description.md`

見出しはrepoの言語や慣習に合わせてよい。ただし、確定事項、仮説、未決事項の分離と、仕様根拠、作業契約、短命な作業コンテクストの分類は維持する。

## 出力ルール

- 長い助言だけで終わらせず、具体的なMarkdown文書を優先する。
- ファイルを書く場合は、依頼されたもの、または合意した最小セットだけを作る。
- Codexでファイルを作成または更新する場合は、手作業のMarkdown作成にも `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。
- ユーザーがまだ検討中なら、先に提案ファイルツリーと文書サンプル1つを出す。
- custom agentは標準では追加しない。セキュリティレビュー、テスト弱体化レビュー、リリース判断、secret/PII露出確認のように、バイアスを避ける必要がある作業に限って別reviewer agentを提案する。
