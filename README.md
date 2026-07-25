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

- skill: repo直下の各 `SKILL.md` を持つディレクトリを `~/.agents/skills/<skill-name>` へ配置
- agent: `agents/*.toml` を `~/.codex/agents/<agent-name>.toml` へ配置

Linux / macOS では symlink を作る。既存pathは上書きしない。

Windows では symlink を使わず copy する。既存pathがある場合は確認を出し、`y` または `yes` の場合だけ上書きする。

旧 `~/.codex/skills` に同名Skillがある場合、install scriptは削除や移動を行わない。現行 `~/.agents/skills` への配置を確認してから、重複する旧pathを利用者が別途確認する。

## Skill Invocation Policy

共通 workflow skill は、原則としてユーザーまたは上流の成果物が `$wf-explore` のように skill 名を明示した場合に使う。Skill本体は現行Codexの共通配置先である `~/.agents/skills` へ、custom agentは `~/.codex/agents` または `$CODEX_HOME/agents` へ配置する。

feedback / 補助 / scaffold / audit 系 skill は、ユーザーが自然文で判断整理、成果物作成、点検そのものを直接頼んだ場合にも使える。

- `feedback-to-criteria`: Codexの提案、判断、質問、説明、操作、生成物への否定、修正、差戻し、範囲限定を、個別修正または根拠のある判断基準へ整理する依頼
- `idiot`: blocked理由、未確認事項、人間判断待ちを判断質問へ整理する依頼
- `scaffold-project`: AI利用開始の仕様根拠、作業契約、AGENTS、短命な作業コンテクスト雛形、Reviewable Gateを作る依頼
- `scaffold-agent-prep-scout`: `wf-explore` 用のread-only prep scout、repo-local supplement、作業コンテクストのevidence欄を整備する依頼
- `scaffold-agent-test-runner`: repo内 `test_runner` agent や検証手順を整備する依頼
- `scaffold-agent-reviewer`: repo固有の専門reviewer、reviewable gate実装、review routingを整備する依頼
- `audit-docs`: README、AGENTS、仕様根拠、作業契約、検証手順、review条件の矛盾や古い前提を点検し、作業結果から長期保存すべき内容をバックポートする依頼
- `audit-repo-skill`: repo内skill、custom agent、AGENTS、review routing、検証手順の整合を点検する依頼
- `audit-workflow`: repo内ドキュメントやAGENTS.mdで定義された `wf-*` 系workflowが、一時worktree上でsubagentとして起動した仮想Main Agentにより完走できるか検証し、repo-local不足を自己改善する依頼
- `migrate-workflow`: 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を共通workflowへ寄せる移行計画を作る依頼

自然文で使う場合でも、実装、検証、review判定などの工程workflowを代替しない。ユーザー依頼がそのskillの判断整理、成果物、点検目的に直接一致する場合だけ使う。audit系skillで人間判断が不要な修正を見つけた場合は、同じ作業内で修正し、判断が必要なものだけ戻り先を整理する。

仕様根拠と作業契約の整合auditも同じく、`project_doc_auditor` custom agentへ委譲する。このagentはread-heavyな監査向けに `gpt-5.6-terra`、`high` reasoning、read-only sandboxを使う。Main Agent は `audit-docs` の点検を自分で実行せず、audit結果のうち人間判断が不要なバックポートまたは文書修正だけを適用する。

検証はrepo内にscaffoldされた `test_runner` custom agentへ委譲する。Main Agent は `wf-verify` や検証コマンドを直接実行しない。formatterやformat checkは、repo手順でMain Agent担当とされる場合だけ例外として実行し、その結果を検証証跡へ渡す。

reviewable gateはrepo-local supplementで定義された実装を使う。reviewable gate用custom agentへ委譲する方式、または専門reviewer結果とgate文書の照合でgate summaryを作る方式を許容する。Main Agent は証跡なしに `wf-review` を代替判定しない。

実装済みtest artifactが変わる場合、`wf-review` は共通の `test_reviewer` custom agentへ `$review-tests` を委譲し、その結果をrepo-local gateへ渡す。`review-tests` はテスト計画を対象にしないため、`wf-explore` のpre-implementation reviewでは呼ばない。

同一 `wf-implement` 実行中の `test_runner` は、最初のsession idを保持し、原則として同じagent sessionを再利用する。新しいsessionは、古いdiff、古いcheckout、壊れた環境状態、誤った前提、別task、別ブランチ、別worktreeなどの理由がある場合だけ使い、理由を検証証跡に残す。reviewable gateの最終判定は、原則としてreview iterationごとに新しいreviewer sessionを使う。専門reviewerや前回指摘の解消確認は、同一task内で同じ観点を継続確認する場合に限り再利用してよい。

## Skill 一覧

### Main Workflow

| Skill | 役割 |
| --- | --- |
| `wf-explore` | 実装前に調査、実装計画、pre-implementation review、修正開始可否、人間レビュー観点、最後の判断質問整理を単一の作業コンテクストで行う。人間がレビューして承認するまで実装を始めない。 |
| `wf-implement` | 人間が承認した計画を authority として、計画範囲内の実装、対応テスト、自己確認、検証、`audit-docs`、`wf-review` まで進める。 |
| `wf-verify` | repo内 `test_runner` が、実装後または reviewable gate 前に必要な検証範囲を確定し、検証コマンドを実行して検証証跡をまとめる。 |
| `wf-review` | repo-local reviewable gate実装が、差分が人間レビューや専門 review へ進める状態か、計画、diff、テスト、計画時のドキュメント根拠、検証結果などの証跡から判定する。 |
| `wf-review-triage` | 人間 review、専門 review、reviewable gate の指摘を、計画内修正、ドキュメント根拠不足、検証不足、再計画、追加調査、人間判断などに分類する。 |

### Review Support

| Skill | 役割 |
| --- | --- |
| `review-tests` | `wf-review` から実装済みtest artifactを受け取り、oracle、意味のある境界、test弱体化、flakiness候補を `test_reviewer` がread-onlyでレビューする。`wf-explore` では使わない。 |

### Clarification And Handoff

| Skill | 役割 |
| --- | --- |
| `feedback-to-criteria` | Codexが生成または選択した内容への否定、修正、差戻し、範囲限定を分類し、今回だけの修正と再利用可能な判断基準を分ける。既存方針との重複と一般化の根拠を確認し、関係のない成果物へ変更を広げない。 |
| `idiot` | blocked 理由や人間判断待ちを、判断質問へ変換する。仕様決定、実装、検証、review 判定は行わない。 |
| `handoff` | 調査、計画、実装証跡、検証証跡、review 結果などを、次のAIセッションが読める handoff packet に整理する。 |
| `audit-docs` | README、AGENTS、仕様根拠、作業契約、検証手順、review条件、作業コンテクストMarkdownとstate fileを横断し、文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを点検する。作業結果から長期保存すべき内容を `docs/spec/` または `docs/contract/` へバックポートする。 |

### Scaffold And Audit

| Skill | 役割 |
| --- | --- |
| `scaffold-project` | 新規プロジェクトや文書が薄い既存プロジェクト向けに、仕様根拠、作業契約、AI 利用ルール、AGENTS.md、短命な作業コンテクスト雛形などを作る。 |
| `scaffold-agent-prep-scout` | `wf-explore` の前処理として、repo 固有の read-only prep scout agent、workflow supplement、作業コンテクストの evidence 記録欄を設計、提案、作成する。 |
| `scaffold-agent-reviewer` | `wf-explore` の pre-implementation review と `wf-review` を補完する repo 固有の専門 review skill や custom agent を設計、提案、作成する。 |
| `scaffold-agent-test-runner` | repo 内に検証専用の `test_runner` custom agent と、agent が読む repo 固有の検証手順を作る。 |
| `audit-repo-skill` | repo 内の AGENTS.md、`.agents/skills`、`.codex/agents`、review routing、検証手順を点検し、役割重複や危険な権限漏れを見つける。人間判断が不要なskill、agent、文書修正は同じ作業内で行う。 |
| `audit-workflow` | 一時 `git worktree` とsubagentとして起動した仮想Main Agentで、docs / 実装 / test を伴う架空タスクが `wf-explore` から `wf-review` まで完走できるか検証し、scaffold / audit 系skillで補正できるrepo-local不足を自己改善する。 |
| `migrate-workflow` | 成熟済みrepo内の運用docs、repo-local skill、custom agent、review routing、検証手順を、共通workflowへ委譲・削除・残置・分解する計画に整理する。 |

### Subagent Contract

| Skill | 役割 |
| --- | --- |
| `subagent-orchestration` | Main Agent が subagent に作業を委譲するときの共通契約を定める。ownership、handoff、Delegation Packet、stale result の扱いなどを整理する。 |
| `subagent-execution` | subagent 側の共通実行規約を定める。委譲文を authority とし、scope を広げず、`done` / `blocked` の結果状態で返す。 |

## 文書分類

`scaffold-project` で作る文書は、長期保存する根拠と短命な作業入力を分ける。

- `docs/spec/`: 仕様根拠。PJ目的、要件、architecture、画面責務、判断ログを置く。主に `wf-explore` で関連箇所を確認する。
- `docs/contract/`: 作業契約。AI利用ルール、検証コマンド、review条件、workflow map、安全境界を置く。`wf-explore`、`wf-implement`、`audit-docs` が関係範囲を確認する。
- `docs/work/`: 短命な作業コンテクスト。人間が読む `<task-id>.md` と、workflow用の `<task-id>.state.json` を1ペアで使う。state fileは進捗、対象ファイル、関連ファイル、コマンドと結果、Markdownへの参照だけを置き、方針や調査メモはMarkdownへ置く。作業完了後は、残すべき内容だけ `docs/spec/` または `docs/contract/` へバックポートし、個別作業ファイルは削除してよい。

## 基本ワークフロー

通常の変更は、ユーザーまたは作業コンテクストで明示された workflow skill から始める。実装前準備では、コードとテストだけでなく、仕様根拠、作業契約、AGENTS、検証手順、review条件などのドキュメントを根拠資料として確認する。典型的には次の流れになる。

```text
wf-explore
  -> choose pre-implementation reviewer from impact scope
  -> pre-implementation review
  -> update plan memo from pre-implementation review result
  -> human approval
  -> wf-implement
  -> formatter / format check by Main Agent when repo-local rules say so
  -> wf-verify
  -> specialist review when repo-local rules require it
  -> E2E / visual verification when repo-local rules require it
  -> audit-docs
  -> wf-review
     -> test_reviewer / review-tests when test artifacts changed
     -> repo-local reviewable gate
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

1. `scaffold-project` で仕様根拠、作業契約、AI 利用ルール、短命な作業コンテクスト雛形、Reviewable Gate の基本形を作る。
2. 実装前の事実確認や計画候補整理を分離したい場合は、`scaffold-agent-prep-scout` で repo 内 prep scout と `wf-explore` supplement を作る。
3. 検証を実装者から分離したい場合は、`scaffold-agent-test-runner` で repo 内 `test_runner` と検証手順を作る。
4. UI、permission、privacy、data migration など専門 review が必要な領域がある場合は、`scaffold-agent-reviewer` で repo 内 reviewer を作る。`wf-explore` の pre-implementation review では、Main Agent が影響範囲から委譲先reviewerを選ぶ。
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

1. `wf-explore` で、実装前に既存実装、既存テスト、関連ドキュメント、影響範囲、仮説、リスクを整理し、作業コンテクストMarkdownで変更方針、変更予定ファイル、テスト方針、修正開始可否を計画化し、state fileに対象ファイル、関連ファイル、検証コマンド、進捗を記録する。
2. Main Agent は影響範囲から pre-implementation review の委譲先を選び、専門reviewerへ計画メモを渡し、実装時の注意点、後続review観点、計画上の懸念、今回の非対象範囲を返してもらう。
3. Main Agent は pre-implementation review の結果を作業コンテクストへ反映する。指摘をそのまま追加実装要求にせず、scopeや仕様判断が変わる場合は人間判断または追加の `wf-explore` へ戻す。
4. `wf-explore` の最後に、人間が答えるべき判断質問を `Decision Clarification` として整理する。確認事項がなければ「質問はありません。」と返す。
5. 人間承認後、`wf-implement` で実装、対応テスト、自己確認を行う。
6. repo手順でMain Agent担当とされたformatterまたはformat checkを実行し、format完了前にtest、lint、reviewへ進まない。
7. formatter以外の検証は、repo内 `test_runner` custom agentへ `wf-verify` を委譲する。
8. repo-local supplementで必須とされた専門reviewを実行し、blocking issueが残る間はE2Eやvisual確認へ進まない。
9. repo-local supplementに従い、E2E、screenshot、visual確認を後段で実行または委譲する。
10. `wf-implement` から `audit-docs` を呼び、作業コンテクスト、state file、実装差分、検証証跡、review結果から、長期保存すべき内容を `docs/spec/` または `docs/contract/` へバックポートする。人間判断が不要なバックポートや文書修正は同じ作業内で適用し、判断が必要なものは戻り先を記録する。
11. repo-local supplementで定義されたreviewable gate実装へ `wf-review` を渡し、人間レビューや専門 review へ進める状態か、計画時のドキュメント根拠、文書差分、実装差分、検証結果が矛盾していないかを確認する。

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

1. `scaffold-agent-prep-scout` で、repo の `AGENTS.md`、workflow map、repo-local skill、custom agent、作業コンテクストtemplateを調査する。
2. `wf-explore` の前処理として分離する read-only scout を、事実確認担当と計画候補整理担当に分けるか判断する。
3. `.codex/agents/<scout-name>.toml`、repo-local orchestration / execution supplement、`docs/contract/workflow-map.md`、`docs/work/_template.md`、`docs/work/_template.state.json` のうち必要な最小セットを作る。
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

1. `wf-explore` の影響範囲または `wf-review` / repo-local supplement が repo 固有の専門 review を必要とする場合、reviewer の責務、trigger、入力証跡を整理する。
2. `scaffold-agent-reviewer` で、repo 内 review skill、custom agent、routing 文書を作る。
3. 専門 reviewer は修正や検証実行ではなく、専門領域の findings、blocking / non-blocking、人間判断が必要な点を返す。
4. `audit-repo-skill` で、専門 reviewer が release、merge、risk acceptance を承認する記述になっていないか確認する。

実装済みtest artifactの変更はrepo固有reviewerの有無にかかわらず、`wf-review` 内で共通 `test_reviewer` へ `$review-tests` を委譲する。このreviewerはテスト計画しかない `wf-explore` では呼ばない。

### 7. 長い作業を次の agent や次の session へ渡す

候補 workflow:

- `handoff`

流れ:

1. 既存の成果物から、次のAIセッションが再開に使う authority と証跡だけを選ぶ。
2. 読むべきファイル、読まなくてよい背景、禁止事項、完了条件、blocked 条件を packet 化する。
3. 未承認の計画や未回答の判断は authority にせず、Open Items として残す。

### 8. Repo 内 skill / agent を公開前に点検する

候補 workflow:

- `audit-repo-skill`

流れ:

1. AGENTS.md、`.agents/skills`、`.codex/agents`、review routing、verification docs を対象にする。
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
2. 親Main Agentは、仮想Main Agent subagentを起動し、自分では `wf-*` 検証を直接実行しない。
3. 仮想Main Agent subagentが、docs / 実装 / test が必ず変更され、共通workflowとrepo-localで定義された呼び出し候補subagentをすべて呼ぶ架空タスクを選び、`wf-explore`、仮想承認、`wf-implement`、`wf-verify`、`audit-docs`、`wf-review` まで進める。
4. formatter、linter、test、build、typecheck、E2Eは実行せず、未実行理由をWorkflow Traceへ残す。
5. review系subagentが複数ある場合は、1種類だけで代表させず、共通 `test_reviewer`、reviewable gate、specialist reviewer、review triage、visual / evidence reviewerなどの全候補を呼ぶ。
6. repo-local不足があれば scaffold / audit 系skillで補正し、最大2回まで再検証する。
7. `audit_status: pass` または `findings-fixed` の場合、架空差分は人間review対象にせず、Workflow Traceと差分要約を回収して一時worktreeを削除する。
8. 共通skill側の不足で完走できない場合は、repo-local修正へ混ぜず `blocked` とし、対象skillと修正案を報告する。

### 10. 成熟済みrepoの運用資産を共通workflowへ寄せる

候補 workflow:

- `migrate-workflow`
- 必要に応じて `audit-repo-skill`
- 必要に応じて `audit-docs`

流れ:

1. AGENTS.md、docs、repo-local skill、custom agent、review routing、verification docs、代表的な作業コンテクストを対象にする。
2. 既存資産ごとに `delete`、`delegate-to-common`、`keep-repo-local`、`split`、`needs-common-template`、`blocked-human-decision` へ分類する。
3. 共通workflowへの移行先、repo側へ薄く残す内容、参照更新順、削除前の逆参照確認を整理する。
4. 共通側不足を提案する場合でも、repo固有コマンド、reviewer名、app固有ルールは共通skillへ混ぜない。

### 11. 仕様根拠と作業契約を点検しバックポートする

候補 workflow / agent:

- `audit-docs`
- `agents/project_doc_auditor.toml`

流れ:

1. `project_doc_auditor` custom agent へ委譲し、README、AGENTS、仕様根拠、作業契約、検証手順、review条件、対象作業コンテクストMarkdownとstate fileを確認する。
2. 文書同士の矛盾、古い前提、未決事項、実装や検証手順との食い違いを severity 付きで整理する。
3. 作業コンテクスト、state file、実装差分から抽出した内容を `backport-to-spec`、`backport-to-contract`、`task-local`、`human-decision` に分ける。
4. findings を `auto-fixable`、`needs-workflow`、`human-decision`、`no-action` に分ける。
5. 既存証跡から正しい記述が一意に決まる誤記、古い参照、リンク、検証コマンド、説明同期漏れ、または一意に移せるバックポートはMain Agentが同じ作業内で修正する。
6. 事実不足、期待動作やscope整理は `wf-explore`、人間判断は `idiot` または human decision へ戻す。

## 役割境界

- 共通 skill は、共通 workflow、入力、禁止事項、出力形式を定める。
- 工程workflowは、ユーザーまたは上流成果物が `$wf-explore` のように明示した場合に使う。
- repo 固有の検証コマンド、専門 review 観点、custom agent の詳細は、各 repo 内 skill や docs に置く。
- prep scout は `wf-explore` の前処理として事実確認や計画候補整理を行う。実装、検証実行、docs更新、採用判断、計画確定、修正開始可否の判断はしない。
- `test_runner` は検証を実行して証跡を返す。修正や review 判定はしない。
- specialist reviewer は専門領域の review を行う。検証実行、修正、release、merge、risk acceptance はしない。
- 共通 `test_reviewer` は `wf-review` で実装済みtest artifactのoracle、境界、弱体化、flakiness候補をreviewする。検証実行や修正を行わず、`wf-explore` のpre-implementation reviewには参加しない。
- repo-local reviewable gate実装は `wf-review` を使い、レビュー可能条件と routing を判定する。実装は、repo内reviewable gate agent、または専門reviewer結果とgate文書を照合するgate summaryのどちらでもかまわない。repo 固有の深い設計判断を単独では承認しない。
- agent session lifecycleは、`test_runner` については `wf-implement`、reviewerについては `wf-review` の規則に従う。`test_runner` は同一実装作業内で再利用を基本とし、reviewable gateの最終判定はiterationごとに新規sessionを基本とする。
- バグ修正や実装の根拠になる仕様根拠、作業契約、検証手順、AGENTS、review条件は、`wf-explore` で根拠資料として確認する。文書と実態が食い違う場合は、既存証跡だけで直せるものを更新し、それ以外は追加調査、人間判断、または実装前準備へ戻す。
- pre-implementation review は `wf-explore` 内で計画メモに対して常に行う実装前の専門助言である。Main Agent の判断範囲は、影響範囲からどの専門reviewerへ委譲するかである。review自体は共通必須だが、reviewer名、担当領域、入力証跡、反映先の計画メモ欄はrepo-local supplementで定める。Main Agent は結果を作業コンテクストへ反映するが、指摘をそのまま追加実装要求にしない。scope追加、仕様判断、risk acceptanceが必要な場合は人間判断または追加の `wf-explore` へ戻す。
- `wf-implement` は `wf-review` の前に `audit-docs` を呼び、作業コンテクスト、state file、実装差分から長期保存すべき内容を `docs/spec/` または `docs/contract/` へバックポートする。`audit-docs` のfindingは文書整合の扱いであり、実装差分のreview判定や検証結果の代替にはしない。
- `audit-docs` は文書群を点検し、短命な作業コンテクストMarkdownやstate fileを最新化し続けず、必要な内容だけ仕様根拠または作業契約へ移す。`project_doc_auditor` は文書を編集しないが、Main Agent はaudit結果のうち人間判断が不要なバックポートまたは文書修正を適用する。実装、検証、review判定は行わない。
- `audit-workflow` は一時 `git worktree` とsubagentとして起動した仮想Main Agentで、repo-local workflow資材が `wf-*` 系workflowを完走させられるか検証する。親Main Agentは `wf-*` 検証を直接実行しない。共通workflowとrepo-localで定義された呼び出し候補subagentは全てcoverage対象にし、review系subagentが複数ある場合も全て呼ぶ。`pass` または `findings-fixed` の架空差分は要約だけ回収し、一時worktreeを削除する。repo-local不足は scaffold / audit 系skillで補正してよいが、共通skill側の不足は修正案として報告する。
- `migrate-workflow` は成熟済みrepoの運用資産を共通workflowへ寄せる対応表を作る。移行対象ファイルの削除、移動、編集、検証、review判定は行わない。
- `audit-docs` は、この共通repoの `project_doc_auditor` custom agentで実行する。`wf-verify` は各repo内にscaffoldされた `test_runner` で実行する。`wf-review` はtest artifact変更時に共通 `test_reviewer` を使い、その結果を各repoのrepo-local supplementで定義されたgate実装へ渡す。Main Agentは同一agent内で証跡なしに代替判定しない。

## 運用メモ

- 新しい skill を追加したら、`SKILL.md` を置き、必要なら `agents/openai.yaml` も追加する。
- skill 作成または大きな更新後は、`quick_validate.py` で検証する。
- 配布前提のため、skill 本文や公開文書に個人環境のローカルフルパスを固定しない。
- コミットは明示的に依頼された場合だけ行う。

## License

MIT License. See [LICENSE](./LICENSE).
