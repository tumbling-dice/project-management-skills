# Project Management Skills

AI coding agent を使うプロジェクトで、調査、計画、実装、検証、レビュー、引き継ぎを扱うための共通 skill 集です。

このリポジトリは、共通 skill 本体を Git 管理し、Codex の skill ディレクトリから参照して使うことを想定しています。各プロジェクト固有の検証コマンド、専門 reviewer、test runner の詳細は、共通 skill ではなく各 repo 内の skill や custom agent に閉じ込めます。

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

Install script は次を配置します。

- skill: repo直下の各 `SKILL.md` を持つディレクトリを `~/.codex/skills/<skill-name>` へ配置
- agent: `agents/*.toml` を `~/.codex/agents/<agent-name>.toml` へ配置

Linux / macOS では symlink を作ります。既存pathは上書きしません。

Windows では symlink を使わず copy します。既存pathがある場合は確認を出し、`y` または `yes` の場合だけ上書きします。

## Routing Policy

通常の作業依頼では、人間や Main Agent が個別 workflow skill を直接選ぶのではなく、最初に `workflow_router` custom agent へ委譲して次に使う workflow を判定します。Main Agent は `workflow-router` を自分で実行しません。

`workflow-router` 以外の共通 workflow skill は、原則として次の場合だけ使います。

- `workflow-router` の routing 結果で選ばれた場合
- ユーザーが `$implementation-prep-workflow` のように skill 名を明示した場合

ただし、ユーザーが自然文で判断整理、成果物作成、点検そのものを直接頼みやすい補助 / scaffold / audit 系 skill は、自然発火を許可します。

- `decision-clarification-workflow`: blocked理由、未確認事項、人間判断待ちを少数の判断質問へ整理する依頼
- `project-startup-scaffold`: AI利用開始の初期文書、AGENTS、作業メモ雛形、Reviewable Gateを作る依頼
- `test-runner-scaffold`: repo内 `test_runner` agent や検証手順を整備する依頼
- `specialist-reviewer-scaffold`: repo固有の専門reviewer、reviewable gate agent、review routingを整備する依頼
- `project-doc-consistency-audit`: README、AGENTS、PJ文書、検証手順、review条件の矛盾や古い前提を点検する依頼
- `repo-skill-audit`: repo内skill、custom agent、AGENTS、review routing、検証手順の整合を点検する依頼
- `repo-workflow-migration-plan`: 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を共通workflowへ寄せる移行計画を作る依頼

自然発火を許可する場合でも、実装、検証、review判定などの厳密な工程workflowを代替しません。ユーザー依頼がそのskillの判断整理、成果物、点検目的に直接一致する場合だけ使います。audit系skillで人間判断が不要な修正を見つけた場合は、同じ作業内で修正し、判断が必要なものだけ戻り先を整理します。

`workflow-router` は routing 結果を会話で返すだけで、ファイル作成、ファイル更新、実装、検証、レビュー判定は行いません。

`workflow_router` custom agent が使えない場合、Main Agent は同一agentで代替routingせず、必要なagentが無いことを報告して停止します。代替routingは、このskill群自体の開発・検証で明示された場合だけです。

PJ文書群の整合auditも同じく、`project_doc_auditor` custom agentへ委譲します。Main Agent は `project-doc-consistency-audit` の点検を自分で実行しません。audit結果のうち、人間判断が不要な文書修正はMain Agentが適用します。

検証はrepo内にscaffoldされた `test_runner` custom agentへ委譲します。Main Agent は `verification-workflow` や検証コマンドを直接実行しません。

reviewable gateはrepo内にscaffoldされた reviewable gate用custom agentへ委譲します。Main Agent は `reviewable-gate-review` を自分で実行しません。

## Skill 一覧

### Main Workflow

| Skill | 役割 |
| --- | --- |
| `workflow-router` | ユーザー依頼や現在の成果物から、次に使うべきworkflow skillを判定します。対象workflowの実行、実装、検証、review判定は行いません。 |
| `implementation-prep-workflow` | 実装前に調査、実装計画、修正開始可否、人間レビュー観点、最後の判断質問整理を単一の作業コンテクストで行います。人間がレビューして承認するまで実装を始めません。 |
| `implementation-execution-workflow` | 人間が承認した計画を authority として、計画範囲内の実装、対応テスト、自己確認、検証、`reviewable-gate-review` まで進めます。 |
| `verification-workflow` | repo内 `test_runner` が、実装後または reviewable gate 前に必要な検証範囲を確定し、検証コマンドを実行して検証証跡をまとめます。 |
| `reviewable-gate-review` | repo内reviewable gate agentが、差分が人間レビューや専門 review へ進める状態か、計画、diff、テスト、計画時のドキュメント根拠、検証結果などの証跡から判定します。 |
| `post-review-fix-triage` | 人間 review、専門 review、reviewable gate の指摘を、計画内修正、ドキュメント根拠不足、検証不足、再計画、追加調査、人間判断などに分類します。 |

### Clarification And Handoff

| Skill | 役割 |
| --- | --- |
| `decision-clarification-workflow` | blocked 理由や人間判断待ちを、少数の判断質問へ変換します。仕様決定、実装、検証、review 判定は行いません。 |
| `workflow-artifact-handoff` | 調査、計画、実装証跡、検証証跡、review 結果などを、次 workflow へ渡せる handoff packet に整理します。 |
| `project-doc-consistency-audit` | README、AGENTS、PJ文書、検証手順、review条件、代表的な作業メモを横断し、文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを点検します。人間判断が不要な文書修正は同じ作業内で行います。 |

### Scaffold And Audit

| Skill | 役割 |
| --- | --- |
| `project-startup-scaffold` | 新規プロジェクトや文書が薄い既存プロジェクト向けに、初期コンテキスト、AI 利用ルール、AGENTS.md、作業メモ雛形などを作ります。 |
| `specialist-reviewer-scaffold` | `reviewable-gate-review` を補完する repo 固有の専門 review skill や custom agent を設計、提案、作成します。 |
| `test-runner-scaffold` | repo 内に検証専用の `test_runner` custom agent と、agent が読む repo 固有の検証手順を作ります。 |
| `repo-skill-audit` | repo 内の AGENTS.md、`.codex/skills`、`.codex/agents`、review routing、検証手順を点検し、役割重複や危険な権限漏れを見つけます。人間判断が不要なskill、agent、文書修正は同じ作業内で行います。 |
| `repo-workflow-migration-plan` | 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を、共通workflowへ委譲・削除・残置・分解する計画に整理します。 |

### Subagent Contract

| Skill | 役割 |
| --- | --- |
| `subagent-orchestration` | Main Agent が subagent に作業を委譲するときの共通契約を定めます。ownership、handoff、Delegation Packet、stale result の扱いなどを整理します。 |
| `subagent-execution` | subagent 側の共通実行規約を定めます。委譲文を authority とし、scope を広げず、`done` / `blocked` の結果状態で返します。 |

## 基本ワークフロー

通常の変更は、必ず `workflow-router` で次 workflow を判定してから進めます。実装前準備では、コードとテストだけでなく、要件、設計、AGENTS、検証手順、review条件などのドキュメントを根拠資料として確認します。典型的には次の流れになります。

```text
workflow-router
  -> implementation-prep-workflow
  -> human approval
  -> implementation-execution-workflow
  -> verification-workflow
  -> reviewable-gate-review
  -> human review / specialist review
```

実装中または review 後に問題が見つかった場合は、内容に応じて戻り先を分けます。

```text
review comments / gate result
  -> post-review-fix-triage
  -> implementation-execution-workflow
     / verification-workflow
     / implementation-prep-workflow
     / decision-clarification-workflow
     / human decision
```

長い作業を別 agent、別セッション、後日の作業へ渡す場合は、成果物を先に整理します。

```text
current artifacts
  -> workflow-router
  -> workflow-artifact-handoff
  -> next workflow
```

## ユースケース

### 0. 次に使う workflow を判断する

入口:

- `agents/workflow_router.toml`
- governing skill: `workflow-router`

流れ:

1. Main Agent が、ユーザー依頼、現在の作業段階、承認済み計画の有無、成果物の有無を短く整理します。
2. `workflow_router` custom agent に明示的な材料だけを渡します。
3. `workflow_router` が、次に使う primary skill、必要な入力、止まる条件、次に使うpromptを決めます。
4. routing後、Main Agent が該当workflow skillを実行します。

`workflow_router` は会話履歴の要約係ではありません。Main Agentが渡した明示的な成果物、ファイル名、status、review結果だけを材料にします。

### 1. 新規プロジェクトを AI coding agent 向けに立ち上げる

候補 workflow:

- `project-startup-scaffold`
- 必要に応じて `test-runner-scaffold`
- 必要に応じて `specialist-reviewer-scaffold`
- 仕上げに `repo-skill-audit`

流れ:

1. `workflow-router` で、立ち上げ文書作成から始めるべきかを判定します。
2. `project-startup-scaffold` でプロジェクト初期文書、AI 利用ルール、作業メモ雛形、Reviewable Gate の基本形を作ります。
3. 検証を実装者から分離したい場合は、`test-runner-scaffold` で repo 内 `test_runner` と検証手順を作ります。
4. UI、permission、privacy、data migration など専門 review が必要な領域がある場合は、`specialist-reviewer-scaffold` で repo 内 reviewer を作ります。
5. `repo-skill-audit` で、役割境界、検証手順、routing、配布性、security 観点を確認します。

### 2. バグ修正や小さな機能追加を進める

候補 workflow:

- `implementation-prep-workflow`
- `decision-clarification-workflow`
- `implementation-execution-workflow`
- `verification-workflow`
- `reviewable-gate-review`

流れ:

1. `workflow-router` で、実装前準備、実装、検証、review gate のどこから始めるかを判定します。
2. `implementation-prep-workflow` で、実装前に既存実装、既存テスト、関連ドキュメント、影響範囲、仮説、リスクを整理し、同じ作業コンテクストで変更方針、変更予定ファイル、テスト方針、検証コマンド、修正開始可否を計画化します。
3. `implementation-prep-workflow` の最後に、人間が答えるべき判断質問を `Decision Clarification` として絞ります。確認事項がなければ質問数0として報告します。
4. 人間承認後、`implementation-execution-workflow` で実装、対応テスト、自己確認を行います。
5. repo内 `test_runner` custom agentへ `verification-workflow` を委譲します。
6. repo内reviewable gate agentへ `reviewable-gate-review` を委譲し、人間レビューや専門 review へ進める状態か、計画時のドキュメント根拠と差分が矛盾していないかを確認します。

### 3. Review 指摘を受けて再修正する

候補 workflow:

- `post-review-fix-triage`
- `implementation-execution-workflow`
- `verification-workflow`
- `reviewable-gate-review`
- 必要に応じて `decision-clarification-workflow`

流れ:

1. `workflow-router` で、指摘をtriageすべきか、すでに修正scopeが確定しているかを判定します。
2. 人間 review、specialist review、`reviewable-gate-review` の指摘を `post-review-fix-triage` に渡します。
3. 指摘を `fix-in-plan`、`verify-only`、`re-plan`、`investigate`、`human-decision`、`specialist-review`、`non-blocking` に分類します。
4. `fix-in-plan` だけを `implementation-execution-workflow` の再修正 scope として渡します。
5. 検証証跡不足は `verification-workflow`、ドキュメント根拠不足、計画外変更、事実不足は `implementation-prep-workflow`、リスク受容は `decision-clarification-workflow` または human decision へ戻します。

### 4. 検証専用 agent を repo 内に整備する

候補 workflow / skill:

- `test-runner-scaffold`
- `verification-workflow`
- `subagent-orchestration`
- `subagent-execution`

流れ:

1. `workflow-router` で、検証実行ではなく test runner 整備が目的かを判定します。
2. `test-runner-scaffold` で、repo の検証コマンド、artifact、timeout、sandbox 権限、禁止操作を調査します。
3. `.codex/agents/test_runner.toml` と repo 内 verification skill または docs を作ります。
4. Main Agent は `subagent-orchestration` の Delegation Packet でrepo内 `test_runner` へ `verification-workflow` を委譲します。
5. `test_runner` は `subagent-execution` に従い、指定された検証だけを実行し、`done` / `blocked` と検証証跡を返します。

### 5. 専門 reviewer を repo 内に整備する

候補 workflow:

- `specialist-reviewer-scaffold`
- `reviewable-gate-review`
- 必要に応じて `repo-skill-audit`

流れ:

1. `workflow-router` で、review実行ではなく専門 reviewer 整備が目的かを判定します。
2. `reviewable-gate-review` が repo 固有の専門 review を必要と判断したら、必要な reviewer の責務、trigger、入力証跡を整理します。
3. `specialist-reviewer-scaffold` で、repo 内 review skill、custom agent、routing 文書を作ります。
4. 専門 reviewer は修正や検証実行ではなく、専門領域の findings、blocking / non-blocking、人間判断が必要な点を返します。
5. `repo-skill-audit` で、専門 reviewer が release、merge、risk acceptance を承認する記述になっていないか確認します。

### 6. 長い作業を次の agent や次の session へ渡す

候補 workflow:

- `workflow-artifact-handoff`

流れ:

1. `workflow-router` で、次workflowの実行ではなくhandoff packet作成が目的かを判定します。
2. 既存の成果物から、次 workflow に必要な authority と証跡だけを選びます。
3. `workflow-artifact-handoff` で handoff type を選びます。
   - `prep-to-execution`
   - `plan-to-execution`
   - `execution-to-verification`
   - `verification-to-reviewable-gate`
   - `review-to-triage`
   - `triage-to-execution`
   - `general-continuation`
4. 次 workflow が読むべきファイル、読まなくてよい背景、禁止事項、完了条件、blocked 条件を packet 化します。
5. 未承認の計画や未回答の判断は authority にせず、Open Items として残します。

### 7. Repo 内 skill / agent を公開前に点検する

候補 workflow:

- `repo-skill-audit`

流れ:

1. `workflow-router` で、実装修正ではなくauditが目的かを判定します。
2. AGENTS.md、`.codex/skills`、`.codex/agents`、review routing、verification docs を対象にします。
3. 役割境界、workflow routing、配布性、検証と権限、security 観点で findings を出します。
4. findings を `auto-fixable`、`needs-workflow`、`human-decision` に分けます。
5. 人間判断が不要な誤記、古いpath、古いコマンド、明白な説明同期漏れは同じ作業内で修正します。
6. blocking / high finding のうち自動修正できないものは、先に直す順序を整理します。
7. scaffold、移行計画、人間判断が必要なものは、該当する scaffold skill、workflow、または human decision へ戻します。

### 8. 成熟済みrepoの運用資産を共通workflowへ寄せる

候補 workflow:

- `repo-workflow-migration-plan`
- 必要に応じて `repo-skill-audit`
- 必要に応じて `project-doc-consistency-audit`

流れ:

1. `workflow-router` で、公開前点検ではなく移行対応表の作成が目的かを判定します。
2. AGENTS.md、docs、repo-local skill、custom agent、review routing、verification docs、代表的な作業メモを対象にします。
3. 既存資産ごとに `delete`、`delegate-to-common`、`keep-repo-local`、`split`、`needs-common-template`、`blocked-human-decision` へ分類します。
4. 共通workflowへの移行先、repo側へ薄く残す内容、参照更新順、削除前の逆参照確認を整理します。
5. 共通側不足を提案する場合でも、repo固有コマンド、reviewer名、app固有ルールは共通skillへ混ぜません。

### 9. PJ文書群を実装計画の根拠として点検する

候補 workflow / agent:

- `project-doc-consistency-audit`
- `agents/project_doc_auditor.toml`

流れ:

1. `workflow-router` で、実装や計画ではなくPJ文書群の整合auditが目的かを判定します。
2. `project_doc_auditor` custom agent へ委譲し、README、AGENTS、PJ文書、検証手順、review条件、代表的な作業メモを確認します。
3. 文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを severity 付きで整理します。
4. findings を `auto-fixable`、`needs-workflow`、`human-decision` に分けます。
5. 既存証跡から正しい記述が一意に決まる誤記、古い参照、リンク、検証コマンド、説明同期漏れはMain Agentが同じ作業内で修正します。
6. 事実不足、期待動作やscope整理は `implementation-prep-workflow`、人間判断は `decision-clarification-workflow` または human decision へ戻します。

## 役割境界

- 共通 skill は、共通 workflow、入力、禁止事項、出力形式を定めます。
- `workflow-router` 以外の共通 workflow skill は、通常依頼から直接自然発火させません。
- repo 固有の検証コマンド、専門 review 観点、custom agent の詳細は、各 repo 内 skill や docs に置きます。
- `test_runner` は検証を実行して証跡を返します。修正や review 判定はしません。
- specialist reviewer は専門領域の review を行います。検証実行、修正、release、merge、risk acceptance はしません。
- repo内reviewable gate agentは `reviewable-gate-review` を実行し、レビュー可能条件と routing を判定します。repo 固有の深い設計判断を単独では承認しません。
- バグ修正や実装の根拠になる要件、設計、検証手順、AGENTS、review条件は、`implementation-prep-workflow` で根拠資料として確認します。文書と実態が食い違う場合は、既存証跡だけで直せるものを更新し、それ以外は追加調査、人間判断、または実装前準備へ戻します。
- `project-doc-consistency-audit` は文書群を点検します。`project_doc_auditor` は文書を編集しませんが、Main Agent はaudit結果のうち人間判断が不要な文書修正を適用します。実装、検証、review判定は行いません。
- `repo-workflow-migration-plan` は成熟済みrepoの運用資産を共通workflowへ寄せる対応表を作ります。移行対象ファイルの削除、移動、編集、検証、review判定は行いません。
- `workflow-router` と `project-doc-consistency-audit` は、この共通repoの `workflow_router`、`project_doc_auditor` custom agentで実行します。`verification-workflow` と `reviewable-gate-review` は、各repo内にscaffoldされた `test_runner` とreviewable gate用custom agentで実行します。Main Agentは同一agent内で代替実行しません。

## 運用メモ

- 新しい skill を追加したら、`SKILL.md` を置き、必要なら `agents/openai.yaml` も追加します。
- skill 作成または大きな更新後は、`quick_validate.py` で検証します。
- 配布前提のため、skill 本文や公開文書に個人環境のローカルフルパスを固定しません。
- コミットは明示的に依頼された場合だけ行います。

## License

MIT License. See [LICENSE](./LICENSE).
