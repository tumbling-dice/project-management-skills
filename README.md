# Project Management Skills

AI coding agent を使うプロジェクトで、調査、計画、実装、検証、レビュー、引き継ぎを扱うための共通 skill 集である。

このリポジトリは、共通 skill 本体を Git 管理し、Codex の skill ディレクトリから参照して使うことを想定している。各プロジェクト固有の検証コマンド、専門 reviewer、test runner の詳細は、共通 skill ではなく各 repo 内の skill や custom agent に閉じ込める。

## Install

Linux / macOS:

```bash
./scripts/install.sh
```

Windows PowerShell:

```powershell
.\scripts\install.ps1
```

確認だけしたい場合:

```bash
./scripts/install.sh --dry-run
```

```powershell
.\scripts\install.ps1 -DryRun
```

Install script は次を配置する。

- skill: repo直下の各 `SKILL.md` を持つディレクトリを `~/.codex/skills/<skill-name>` へ配置
- agent: `agents/*.toml` を `~/.codex/agents/<agent-name>.toml` へ配置

Linux / macOS では symlink を作る。既存pathは上書きしない。

Windows では symlink を使わず copy する。既存pathがある場合は確認を出し、`y` または `yes` の場合だけ上書きする。

## Skill Invocation Policy

共通 workflow skill は、原則としてユーザーまたは上流の成果物が `$wf-explore` のように skill 名を明示した場合に使う。

補助 / scaffold / audit 系 skill は、ユーザーが自然文で判断整理、成果物作成、点検そのものを直接頼んだ場合にも使える。

- `idiot`: blocked理由、未確認事項、人間判断待ちを少数の判断質問へ整理する依頼
- `scaffold-project`: AI利用開始の初期文書、AGENTS、作業メモ雛形、Reviewable Gateを作る依頼
- `scaffold-agent-prep-scout`: `wf-explore` 用のread-only prep scout、repo-local supplement、作業メモのevidence欄を整備する依頼
- `scaffold-agent-test-runner`: repo内 `test_runner` agent や検証手順を整備する依頼
- `scaffold-agent-reviewer`: repo固有の専門reviewer、reviewable gate実装、review routingを整備する依頼
- `audit-docs`: README、AGENTS、PJ文書、検証手順、review条件の矛盾や古い前提を点検する依頼
- `audit-repo-skill`: repo内skill、custom agent、AGENTS、review routing、検証手順の整合を点検する依頼
- `audit-workflow`: repo内ドキュメントやAGENTS.mdで定義された `wf-*` 系workflowが一時worktree上で完走できるか検証し、repo-local不足を自己改善する依頼
- `migrate-workflow`: 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を共通workflowへ寄せる移行計画を作る依頼

自然文で使う場合でも、実装、検証、review判定などの工程workflowを代替しない。ユーザー依頼がそのskillの判断整理、成果物、点検目的に直接一致する場合だけ使う。audit系skillで人間判断が不要な修正を見つけた場合は、同じ作業内で修正し、判断が必要なものだけ戻り先を整理する。

PJ文書群の整合auditも同じく、`project_doc_auditor` custom agentへ委譲する。Main Agent は `audit-docs` の点検を自分で実行しない。audit結果のうち、人間判断が不要な文書修正はMain Agentが適用する。

検証はrepo内にscaffoldされた `test_runner` custom agentへ委譲する。Main Agent は `wf-verify` や検証コマンドを直接実行しない。formatterやformat checkは、repo手順でMain Agent担当とされる場合だけ例外として実行し、その結果を検証証跡へ渡す。

reviewable gateはrepo-local supplementで定義された実装を使う。reviewable gate用custom agentへ委譲する方式、または専門reviewer結果とgate文書の照合でgate summaryを作る方式を許容する。Main Agent は証跡なしに `wf-review` を代替判定しない。

## Skill 一覧

### Main Workflow

| Skill | 役割 |
| --- | --- |
| `wf-explore` | 実装前に調査、実装計画、修正開始可否、人間レビュー観点、最後の判断質問整理を単一の作業コンテクストで行う。人間がレビューして承認するまで実装を始めない。 |
| `wf-implement` | 人間が承認した計画を authority として、計画範囲内の実装、対応テスト、自己確認、検証、`audit-docs`、`wf-review` まで進める。 |
| `wf-verify` | repo内 `test_runner` が、実装後または reviewable gate 前に必要な検証範囲を確定し、検証コマンドを実行して検証証跡をまとめる。 |
| `wf-review` | repo-local reviewable gate実装が、差分が人間レビューや専門 review へ進める状態か、計画、diff、テスト、計画時のドキュメント根拠、検証結果などの証跡から判定する。 |
| `wf-review-triage` | 人間 review、専門 review、reviewable gate の指摘を、計画内修正、ドキュメント根拠不足、検証不足、再計画、追加調査、人間判断などに分類する。 |

### Clarification And Handoff

| Skill | 役割 |
| --- | --- |
| `idiot` | blocked 理由や人間判断待ちを、少数の判断質問へ変換する。仕様決定、実装、検証、review 判定は行わない。 |
| `handoff` | 調査、計画、実装証跡、検証証跡、review 結果などを、次 workflow へ渡せる handoff packet に整理する。 |
| `audit-docs` | README、AGENTS、PJ文書、検証手順、review条件、代表的な作業メモを横断し、文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを点検する。人間判断が不要な文書修正は同じ作業内で行う。 |

### Scaffold And Audit

| Skill | 役割 |
| --- | --- |
| `scaffold-project` | 新規プロジェクトや文書が薄い既存プロジェクト向けに、初期コンテキスト、AI 利用ルール、AGENTS.md、作業メモ雛形などを作る。 |
| `scaffold-agent-prep-scout` | `wf-explore` の前処理として、repo 固有の read-only prep scout agent、workflow supplement、作業メモの evidence 記録欄を設計、提案、作成する。 |
| `scaffold-agent-reviewer` | `wf-review` を補完する repo 固有の専門 review skill や custom agent を設計、提案、作成する。 |
| `scaffold-agent-test-runner` | repo 内に検証専用の `test_runner` custom agent と、agent が読む repo 固有の検証手順を作る。 |
| `audit-repo-skill` | repo 内の AGENTS.md、`.codex/skills`、`.codex/agents`、review routing、検証手順を点検し、役割重複や危険な権限漏れを見つける。人間判断が不要なskill、agent、文書修正は同じ作業内で行う。 |
| `audit-workflow` | 一時 `git worktree` と仮想Main Agentで、docs / 実装 / test を伴う架空タスクが `wf-explore` から `wf-review` まで完走できるか検証し、scaffold / audit 系skillで補正できるrepo-local不足を自己改善する。 |
| `migrate-workflow` | 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を、共通workflowへ委譲・削除・残置・分解する計画に整理する。 |

### Subagent Contract

| Skill | 役割 |
| --- | --- |
| `subagent-orchestration` | Main Agent が subagent に作業を委譲するときの共通契約を定める。ownership、handoff、Delegation Packet、stale result の扱いなどを整理する。 |
| `subagent-execution` | subagent 側の共通実行規約を定める。委譲文を authority とし、scope を広げず、`done` / `blocked` の結果状態で返す。 |

## 基本ワークフロー

通常の変更は、ユーザーまたは作業メモで明示された workflow skill から始める。実装前準備では、コードとテストだけでなく、要件、設計、AGENTS、検証手順、review条件などのドキュメントを根拠資料として確認する。典型的には次の流れになる。

```text
wf-explore
  -> human approval
  -> wf-implement
  -> formatter / format check by Main Agent when repo-local rules say so
  -> wf-verify
  -> specialist review when repo-local rules require it
  -> E2E / visual verification when repo-local rules require it
  -> audit-docs
  -> wf-review
  -> human review / specialist review
```

実装中または review 後に問題が見つかった場合は、内容に応じて戻り先を分ける。

```text
review comments / gate result
  -> wf-review-triage
  -> wf-implement
     / wf-verify
     / wf-explore
     / idiot
     / human decision
```

長い作業を別 agent、別セッション、後日の作業へ渡す場合は、成果物を先に整理する。

```text
current artifacts
  -> handoff
  -> next workflow
```

## ユースケース

### 1. 新規プロジェクトを AI coding agent 向けに立ち上げる

候補 workflow:

- `scaffold-project`
- 必要に応じて `scaffold-agent-prep-scout`
- 必要に応じて `scaffold-agent-test-runner`
- 必要に応じて `scaffold-agent-reviewer`
- 仕上げに `audit-repo-skill`

流れ:

1. `scaffold-project` でプロジェクト初期文書、AI 利用ルール、作業メモ雛形、Reviewable Gate の基本形を作る。
2. 実装前の事実確認や計画候補整理を分離したい場合は、`scaffold-agent-prep-scout` で repo 内 prep scout と `wf-explore` supplement を作る。
3. 検証を実装者から分離したい場合は、`scaffold-agent-test-runner` で repo 内 `test_runner` と検証手順を作る。
4. UI、permission、privacy、data migration など専門 review が必要な領域がある場合は、`scaffold-agent-reviewer` で repo 内 reviewer を作る。
5. `audit-repo-skill` で、役割境界、検証手順、配布性、security 観点を確認する。

### 2. バグ修正や小さな機能追加を進める

候補 workflow:

- `wf-explore`
- `idiot`
- `wf-implement`
- `wf-verify`
- `wf-review`
- `audit-docs`

流れ:

1. `wf-explore` で、実装前に既存実装、既存テスト、関連ドキュメント、影響範囲、仮説、リスクを整理し、同じ作業コンテクストで変更方針、変更予定ファイル、テスト方針、検証コマンド、修正開始可否を計画化する。
2. `wf-explore` の最後に、人間が答えるべき判断質問を `Decision Clarification` として絞る。確認事項がなければ質問数0として報告する。
3. 人間承認後、`wf-implement` で実装、対応テスト、自己確認を行う。
4. repo手順でMain Agent担当とされたformatterまたはformat checkを実行し、format完了前にtest、lint、reviewへ進みない。
5. formatter以外の検証は、repo内 `test_runner` custom agentへ `wf-verify` を委譲する。
6. repo-local supplementで必須とされた専門reviewを実行し、blocking issueが残る間はE2Eやvisual確認へ進みない。
7. repo-local supplementに従い、E2E、screenshot、visual確認を後段で実行または委譲する。
8. `wf-implement` から `audit-docs` を呼び、設計書、検証手順、review条件、代表的な作業メモが実装差分に対して古いまま残っていないか確認する。人間判断が不要な文書修正は同じ作業内で適用し、判断が必要なものは戻り先を記録する。
9. repo-local supplementで定義されたreviewable gate実装へ `wf-review` を渡し、人間レビューや専門 review へ進める状態か、計画時のドキュメント根拠、文書差分、実装差分、検証結果が矛盾していないかを確認する。

### 3. Review 指摘を受けて再修正する

候補 workflow:

- `wf-review-triage`
- `wf-implement`
- `wf-verify`
- `wf-review`
- 必要に応じて `idiot`

流れ:

1. 人間 review、specialist review、`wf-review` の指摘を `wf-review-triage` に渡す。
2. 指摘を `fix-in-plan`、`verify-only`、`re-plan`、`investigate`、`human-decision`、`specialist-review`、`non-blocking` に分類する。
3. `fix-in-plan` だけを `wf-implement` の再修正 scope として渡す。
4. 検証証跡不足は `wf-verify`、ドキュメント根拠不足、計画外変更、事実不足は `wf-explore`、リスク受容は `idiot` または human decision へ戻す。

### 4. 実装前の prep scout を repo 内に整備する

候補 workflow / skill:

- `scaffold-agent-prep-scout`
- `wf-explore`
- `subagent-orchestration`
- `subagent-execution`

流れ:

1. `scaffold-agent-prep-scout` で、repo の `AGENTS.md`、workflow map、repo-local skill、custom agent、作業メモtemplateを調査する。
2. `wf-explore` の前処理として分離する read-only scout を、事実確認担当と計画候補整理担当に分けるか判断する。
3. `.codex/agents/<scout-name>.toml`、repo-local orchestration / execution supplement、`docs/ai/workflow-map.md`、`docs/work/_template.md` のうち必要な最小セットを作る。
4. Main Agent は `wf-explore` 中に repo-local supplement を読み、指定された prep scout へ `subagent-orchestration` の Delegation Packet で委譲する。
5. prep scout は実装、検証実行、docs更新、採用判断、計画確定をせず、`done` / `blocked` と evidence を返す。
6. scout未整備や起動不能の場合は、Main Agent が同じ観点を読解で補い、それでも計画確定に必要な事実、scope、risk、文書根拠が不足する場合だけ `wf-explore` を `blocked` にする。

### 5. 検証専用 agent を repo 内に整備する

候補 workflow / skill:

- `scaffold-agent-test-runner`
- `wf-verify`
- `subagent-orchestration`
- `subagent-execution`

流れ:

1. `scaffold-agent-test-runner` で、repo の検証コマンド、artifact、timeout、sandbox 権限、禁止操作を調査する。
2. `.codex/agents/test_runner.toml` と repo 内 verification skill または docs を作る。
3. Main Agent は repo手順で担当するformatterまたはformat checkだけを実行し、それ以外は `subagent-orchestration` の Delegation Packet でrepo内 `test_runner` へ `wf-verify` を委譲する。
4. `test_runner` は `subagent-execution` に従い、指定された検証だけを実行し、`done` / `blocked` と検証証跡を返す。

### 6. 専門 reviewer を repo 内に整備する

候補 workflow:

- `scaffold-agent-reviewer`
- `wf-review`
- 必要に応じて `audit-repo-skill`

流れ:

1. `wf-review` またはrepo-local supplementが repo 固有の専門 review を必要と判断したら、必要な reviewer の責務、trigger、入力証跡を整理する。
2. `scaffold-agent-reviewer` で、repo 内 review skill、custom agent、routing 文書を作る。
3. 専門 reviewer は修正や検証実行ではなく、専門領域の findings、blocking / non-blocking、人間判断が必要な点を返す。
4. `audit-repo-skill` で、専門 reviewer が release、merge、risk acceptance を承認する記述になっていないか確認する。

### 7. 長い作業を次の agent や次の session へ渡す

候補 workflow:

- `handoff`

流れ:

1. 既存の成果物から、次 workflow に必要な authority と証跡だけを選ぶ。
2. `handoff` で handoff type を選ぶ。
   - `prep-to-execution`
   - `plan-to-execution`
   - `execution-to-verification`
   - `verification-to-reviewable-gate`
   - `review-to-triage`
   - `triage-to-execution`
   - `general-continuation`
3. 次 workflow が読むべきファイル、読まなくてよい背景、禁止事項、完了条件、blocked 条件を packet 化する。
4. 未承認の計画や未回答の判断は authority にせず、Open Items として残す。

### 8. Repo 内 skill / agent を公開前に点検する

候補 workflow:

- `audit-repo-skill`

流れ:

1. AGENTS.md、`.codex/skills`、`.codex/agents`、review routing、verification docs を対象にする。
2. 役割境界、workflow routing、配布性、検証と権限、security 観点で findings を出す。
3. findings を `auto-fixable`、`needs-workflow`、`human-decision` に分ける。
4. 人間判断が不要な誤記、古いpath、古いコマンド、明白な説明同期漏れは同じ作業内で修正する。
5. blocking / high finding のうち自動修正できないものは、先に直す順序を整理する。
6. scaffold、移行計画、人間判断が必要なものは、該当する scaffold skill、workflow、または human decision へ戻す。

### 9. wf-* 系workflowが完走できるか検証する

候補 workflow:

- `audit-workflow`
- 必要に応じて `audit-repo-skill`
- 必要に応じて `scaffold-agent-prep-scout`
- 必要に応じて `scaffold-agent-test-runner`
- 必要に応じて `scaffold-agent-reviewer`

流れ:

1. `audit-workflow` で、一時 `git worktree` を作成し、本体worktreeの未コミット差分もpatchとして持ち込む。
2. docs / 実装 / test が必ず変更される架空タスクを選び、仮想Main Agentとして `wf-explore`、仮想承認、`wf-implement`、`wf-verify`、`audit-docs`、`wf-review` まで進める。
3. formatter、linter、test、build、typecheck、E2Eは実行せず、未実行理由をWorkflow Traceへ残す。
4. repo-local不足があれば scaffold / audit 系skillで補正し、最大2回まで再検証する。
5. 共通skill側の不足で完走できない場合は、repo-local修正へ混ぜず `blocked` とし、対象skillと修正案を報告する。

### 10. 成熟済みrepoの運用資産を共通workflowへ寄せる

候補 workflow:

- `migrate-workflow`
- 必要に応じて `audit-repo-skill`
- 必要に応じて `audit-docs`

流れ:

1. AGENTS.md、docs、repo-local skill、custom agent、review routing、verification docs、代表的な作業メモを対象にする。
2. 既存資産ごとに `delete`、`delegate-to-common`、`keep-repo-local`、`split`、`needs-common-template`、`blocked-human-decision` へ分類する。
3. 共通workflowへの移行先、repo側へ薄く残す内容、参照更新順、削除前の逆参照確認を整理する。
4. 共通側不足を提案する場合でも、repo固有コマンド、reviewer名、app固有ルールは共通skillへ混ぜない。

### 11. PJ文書群を実装計画の根拠として点検する

候補 workflow / agent:

- `audit-docs`
- `agents/project_doc_auditor.toml`

流れ:

1. `project_doc_auditor` custom agent へ委譲し、README、AGENTS、PJ文書、検証手順、review条件、代表的な作業メモを確認する。
2. 文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを severity 付きで整理する。
3. findings を `auto-fixable`、`needs-workflow`、`human-decision` に分ける。
4. 既存証跡から正しい記述が一意に決まる誤記、古い参照、リンク、検証コマンド、説明同期漏れはMain Agentが同じ作業内で修正する。
5. 事実不足、期待動作やscope整理は `wf-explore`、人間判断は `idiot` または human decision へ戻す。

## 役割境界

- 共通 skill は、共通 workflow、入力、禁止事項、出力形式を定める。
- 工程workflowは、ユーザーまたは上流成果物が `$wf-explore` のように明示した場合に使う。
- repo 固有の検証コマンド、専門 review 観点、custom agent の詳細は、各 repo 内 skill や docs に置きる。
- prep scout は `wf-explore` の前処理として事実確認や計画候補整理を行う。実装、検証実行、docs更新、採用判断、計画確定、修正開始可否の判断はしない。
- `test_runner` は検証を実行して証跡を返す。修正や review 判定はしない。
- specialist reviewer は専門領域の review を行う。検証実行、修正、release、merge、risk acceptance はしない。
- repo-local reviewable gate実装は `wf-review` を使い、レビュー可能条件と routing を判定する。実装は、repo内reviewable gate agent、または専門reviewer結果とgate文書を照合するgate summaryのどちらでもかまわない。repo 固有の深い設計判断を単独では承認しない。
- バグ修正や実装の根拠になる要件、設計、検証手順、AGENTS、review条件は、`wf-explore` で根拠資料として確認する。文書と実態が食い違う場合は、既存証跡だけで直せるものを更新し、それ以外は追加調査、人間判断、または実装前準備へ戻す。
- `wf-implement` は `wf-review` の前に `audit-docs` を呼び、設計書や検証手順が古いまま残っていないか確認する。`audit-docs` のfindingは文書整合の扱いであり、実装差分のreview判定や検証結果の代替にはしない。
- `audit-docs` は文書群を点検する。`project_doc_auditor` は文書を編集しないが、Main Agent はaudit結果のうち人間判断が不要な文書修正を適用する。実装、検証、review判定は行わない。
- `audit-workflow` は一時 `git worktree` と仮想Main Agentで、repo-local workflow資材が `wf-*` 系workflowを完走させられるか検証する。repo-local不足は scaffold / audit 系skillで補正してよいが、共通skill側の不足は修正案として報告する。
- `migrate-workflow` は成熟済みrepoの運用資産を共通workflowへ寄せる対応表を作る。移行対象ファイルの削除、移動、編集、検証、review判定は行わない。
- `audit-docs` は、この共通repoの `project_doc_auditor` custom agentで実行する。`wf-verify` は各repo内にscaffoldされた `test_runner` で実行する。`wf-review` は各repoのrepo-local supplementで定義されたgate実装を使う。Main Agentは同一agent内で証跡なしに代替判定しない。

## 運用メモ

- 新しい skill を追加したら、`SKILL.md` を置き、必要なら `agents/openai.yaml` も追加する。
- skill 作成または大きな更新後は、`quick_validate.py` で検証する。
- 配布前提のため、skill 本文や公開文書に個人環境のローカルフルパスを固定しない。
- コミットは明示的に依頼された場合だけ行う。

## License

MIT License. See [LICENSE](./LICENSE).
