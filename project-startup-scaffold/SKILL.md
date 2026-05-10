---
name: project-startup-scaffold
description: ユーザーが自然文で、AIコーディングエージェント向けの新規PJ立ち上げ、文書が少ない既存PJの初期整備、AGENTS.md、AI利用ルール、作業メモ雛形、Reviewable Gate、初期検証文書の作成を頼んだ場合に使う。workflow-router のrouting結果、または $project-startup-scaffold の明示でも使う。通常の実装、コードレビュー、成熟済みPJの計画更新には使わない。
---

# プロジェクト立ち上げScaffold

このskillは、AIコーディングエージェントを使うPJで、最初に必要な文書セットを作るためのものです。最初から完全なガバナンスを作るのではなく、最初の小さなタスクに進むための共有文脈、境界、レビュー条件を整えます。

## 基本姿勢

- コード実装から始めない。
- ユーザーの粗い目的、背景、制約、懸念を起点にする。
- 業務意図、安全境界、非対象範囲を勝手に作らないために必要な質問だけをする。
- 不明点は `要確認` として残し、黙って確定しない。
- `確定事項`、`仮説`、`未決事項` を分ける。
- GitHubは任意扱いにする。ユーザーがGitHub利用を明示しない限り、「チケット / 作業メモ / レビュー説明」として扱う。
- secrets、credential、マスキングしていない顧客データ、本番DB接続情報、本番ログの生データを生成文書に含めない。
- 立ち上げ文書は、最初の1〜2週間で読めて更新できる長さに保つ。

## 進め方

1. PJの状態を確認する:
   - 新規PJ、AI向け文書がない既存repo、既存文書の更新のどれか
   - 作成対象の文書セット
   - 判明している技術スタックと未決定事項
   - AIに扱わせてはいけないデータや環境
2. 最小文書セットを提案する。初期値は次の通り:
   - `docs/ai/ai-usage-note.md`
   - `docs/project/pj-charter.md`
   - `docs/project/requirements-brief.md`
   - `docs/project/architecture-brief.md`
   - `AGENTS.md`
   - `docs/work/_template.md`
   - `docs/review/reviewable-gate.md`
   - `docs/verification/smoke-test.md`
3. 不足すると危険な文書や誤解を生む事実だけ、簡潔に確認質問する。
4. 下の関連referenceを読み、対応するtemplateを使って文書を作成または更新する。
5. 最後に次を報告する:
   - 作成または更新した文書
   - `人間が判断する点`
   - `次に小さく試すタスク候補`
   - 作成しなかった文書と理由

## 参照資料

ユーザーが求める文書セットに必要なファイルだけを読む:

- `references/workflow.md`: kickoff全体の流れと文書選択。
- `references/ai-usage-note.md`: 暫定AI利用ルールメモ。
- `references/project-charter.md`: 目的、ユーザー、MVP、非対象範囲、成功条件。
- `references/requirements-brief.md`: ユースケース、業務ルール、権限、データ、E2E候補。
- `references/architecture-brief.md`: 技術、認証、tenant、DB、deploy、ログ方針。
- `references/agent-instructions.md`: `AGENTS.md` / `CLAUDE.md` 初稿ルール。
- `references/work-context.md`: 作業メモと変更説明の雛形。
- `references/reviewable-gate.md`: レビュー開始条件。

## 雛形

文書を作成するときは、`assets/templates/` を転用可能な初期雛形として使う:

- `ai-usage-note.md`
- `project-charter.md`
- `requirements-brief.md`
- `architecture-brief.md`
- `AGENTS.md`
- `work-context.md`
- `change-description.md`
- `reviewable-gate.md`
- `smoke-test.md`

見出しはrepoの言語や慣習に合わせてよい。ただし、確定事項、仮説、未決事項の分離は維持する。

## 出力ルール

- 長い助言だけで終わらせず、具体的なMarkdown文書を優先する。
- ファイルを書く場合は、依頼されたもの、または合意した最小セットだけを作る。
- Codexでファイルを作成または更新する場合は、手作業のMarkdown作成にも `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。
- ユーザーがまだ検討中なら、先に提案ファイルツリーと文書サンプル1つを出す。
- custom agentは標準では追加しない。セキュリティレビュー、テスト弱体化レビュー、リリース判断、secret/PII露出確認のように、バイアスを避ける必要がある作業に限って別reviewer agentを提案する。
