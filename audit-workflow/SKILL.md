---
name: audit-workflow
description: ユーザーが自然文で、repo内ドキュメントやAGENTS.mdで定義された wf-* 系workflowが、git worktreeとsubagentとして起動した仮想Main Agentで完走できるか検証し、scaffold / audit 系skillで補正できるrepo-local不足は同じ作業内で自己改善したいと頼んだ場合に使う。親Main Agentはwf-*検証を直接実行しない。共通skill側の不足で完走できない場合はblockedとして修正案を返す。$audit-workflow の明示でも使う。
---

# audit-workflow

このskillは、repo内の `AGENTS.md`、docs、repo-local skill、custom agent、review routing、検証手順が、`wf-explore` から `wf-implement`、`wf-verify`、`audit-docs`、`wf-review` までの実運用に耐えるかを、一時 `git worktree` とsubagentとして起動した仮想Main Agentで検証するためのworkflowである。

目的は、workflow資材を読むだけの静的点検ではなく、docs / 実装 / test が必ず変更される架空タスクを使って、計画、仮想承認、実装、検証委譲、文書audit、reviewable gate まで完走できる状態へ repo-local 資材を自己改善することである。

## 使う場面

- repo内のAI workflow、`AGENTS.md`、workflow map、repo-local skill、custom agentが、`wf-*` 系workflowで想定通りに使われるか検証したい。
- `test_runner`、prep scout、reviewable gate、specialist reviewer、`project_doc_auditor` との接続不足を、実行シナリオで発見したい。
- scaffold / audit 系skillで補正できるrepo-local不足を同じ作業内で修正し、再検証したい。
- 共通skill側の仕様不足、矛盾、表現不足により完走できない箇所を、repo-local修正と分けて報告したい。

## 使わない場面

- 実際のプロダクト変更を進める場合。その場合は `wf-explore` から始める。
- 単なるrepo-local skill / agentの静的点検だけをしたい場合。その場合は `audit-repo-skill` を使う。
- 仕様根拠や作業契約の矛盾だけを点検したい場合。その場合は `audit-docs` を使う。
- repo固有の `test_runner` やreviewerを最初から作る依頼だけの場合。その場合は該当する `scaffold-*` skillを使う。

## 原則

- 対象がgit repoでない場合は `audit_status: blocked` とする。
- 一時 `git worktree` で検証し、検証中の架空変更を本体worktreeへ混ぜない。
- 本体worktreeに未コミット差分がある場合は、対象差分をpatchとして一時worktreeへ持ち込む。patch作成または適用に失敗した場合は `blocked` とし、失敗理由と未適用pathを返す。
- 親Main Agentは、preflight、一時worktree作成、仮想Main Agent subagentの起動、結果評価、repo-local修正、再検証、cleanup、報告だけを担当する。
- 親Main Agentは、`wf-explore`、`wf-implement`、`wf-verify`、`audit-docs`、`wf-review` の検証シナリオを直接実行しない。
- 検証シナリオは必ず `workflow_audit_virtual_main` として起動したsubagentに実行させる。
- `workflow_audit_virtual_main` は仮想Main Agentとして扱う。`subagent-execution` の対象外であり、`subagent-orchestration` を使って下位subagentを呼び出せる。
- 仮想Main Agentが呼ぶ下位subagentには `subagent-execution` の規約を守らせる。
- 検証中は formatter、linter、test、build、typecheck、E2E、外部network、package install、DB接続、本番操作、secret参照、破壊的コマンドを実行しない。
- 検証コマンドを実行しないことは、このworkflowの制約であり、`not_run` 証跡として扱う。検証コマンドそのものが動くかは判定対象外である。
- 完走を目指す。repo-local不足が scaffold / audit 系skillで補正できるなら同じ作業内で修正し、再検証する。
- 共通skill側の問題または不足で完走できない場合は、repo-local修正へ混ぜず `blocked` として修正案を返す。

## Preflight

1. `git rev-parse --show-toplevel` でgit repoか確認する。
2. `git status --short` で未コミット差分を確認する。
3. repo-local supplement候補を確認する。
   - `AGENTS.md`
   - `.codex/skills/`
   - `.codex/agents/`
   - `docs/contract/`
   - `docs/spec/`
   - `docs/work/`
   - repo固有のworkflow map
4. `wf-explore` で使うprep scout、`wf-verify` で使う `test_runner`、`audit-docs` の `project_doc_auditor`、`wf-review` のreviewable gate実装、専門reviewer routingがあるか確認する。
5. `.codex/agents/`、repo-local supplement、review routing、verification docs、workflow mapから、`wf-*` workflow内で呼び出される可能性があるsubagentをすべて棚卸しする。
   - prep scout系
   - `test_runner`系
   - `project_doc_auditor`
   - reviewable gate系
   - specialist review / review系
   - E2E / visual / evidence確認系
   - repo-local docsやAGENTSでworkflow内呼び出し候補として定義されたagent
6. 棚卸し結果を `Expected Subagent Coverage` として、agent名、role、呼び出しworkflow、trigger条件、必要な入力証跡に分ける。再利用が必要なagentは、期待session数、実session id、再利用有無、新session例外理由も記録対象にする。
7. 既知のrepo-local不足が明白で、scaffold / audit 系skillで補正できる場合は、本検証前に必要最小限だけ修正してよい。

## 一時worktree

1. 一時worktreeを作成する。
2. 本体worktreeの未コミット差分をpatchとして一時worktreeへ適用する。
3. 一時worktree内でだけ架空タスクの `wf-*` 検証を行う。
4. 検証後、一時worktreeの差分要約、作業コンテクストMarkdown、state file、Workflow Trace、blocked理由、未実行検証証跡を回収する。
5. `audit_status: pass` または `audit_status: findings-fixed` の場合、一時worktree内の架空差分は人間review対象ではない。差分要約とWorkflow Traceを回収したら、架空差分が残っていても一時worktreeを削除する。
6. `audit_status: blocked` の場合だけ、未回収の差分、blocked原因の再現に必要な作業コンテクスト、またはpatch適用失敗の調査材料が残っていれば、一時worktreeを削除せず path を報告してよい。
7. cleanupに失敗した場合は、残ったworktree path、理由、手動削除可否を報告する。

## 実行主体

親Main Agentは、次の範囲だけを実行する。

- preflight
- 一時worktreeの作成と未コミット差分patchの適用
- `workflow_audit_virtual_main` subagentの起動
- subagent結果の評価
- repo-local不足の修正
- 最大2回までの再検証判断
- cleanup
- 最終報告

親Main Agentは、一時worktree内で架空タスクの `wf-*` 検証を自分で進めてはいけない。親Main Agentが直接 `wf-explore` や `wf-implement` を実行した場合、そのiterationは無効とし、`common-skill-blocked` として「仮想Main Agent subagentの起動条件が守られていない」と記録する。

`workflow_audit_virtual_main` subagentは、次の範囲を担当する。

- 一時worktree内での架空タスク選定
- `$wf-explore` の実行
- audit目的の仮想承認
- `$wf-implement` の実行
- `$wf-verify`、`audit-docs`、`wf-review` の委譲またはrepo-local gate照合
- Workflow Traceの作成
- 完走を止めたfindingの分類

`workflow_audit_virtual_main` は仮想Main Agentであるため、通常の委譲作業者として `subagent-execution` に縛られない。ただし、このsubagentがさらに呼ぶ下位subagentには、必ず `subagent-execution` を守らせる。

## シナリオ要件

架空タスクは固定fixtureでもrepoに合わせた生成でもよい。ただし、必ず次を満たす。

- docsを修正する必要がある。
- 実装ファイルを修正する必要がある。
- testを追加または更新する必要がある。
- 検証コマンド候補が存在し、実行せず `not_run` 証跡として扱える。
- repo-local review routingまたはreviewable gateの入力証跡を作れる。
- `Expected Subagent Coverage` に列挙した全subagentのtrigger条件を満たす。
- review系subagentが複数ある場合は、1種類だけで代表させない。repo-localで定義されたreviewable gate、specialist reviewer、review triage、visual / evidence reviewerなど、workflow内で呼び出される可能性があるreview系subagentをすべて呼ぶ。
- 単一の小タスクで全subagentを自然に呼べない場合は、同じaudit iteration内の複合タスクとして、複数領域のdocs / 実装 / test変更を含めてよい。
- security、privacy、release、本番操作のrisk acceptanceが必要なtriggerは本採用しない。安全な架空入力、fixture、docs-only risk note、または非本番のtest対象で同じroutingだけを発火させる。

repoに実装やtestが存在しない場合は、`scaffold-project`、`scaffold-agent-test-runner`、`scaffold-agent-reviewer`、`audit-repo-skill` などで補正できるか確認する。補正後も docs / 実装 / test を伴うシナリオを作れない場合は `blocked` とする。

全subagentを呼ぶcoverage taskを作れない場合、`audit_status: pass` にしてはいけない。補正可能なら scaffold / audit 系skillでroutingやtrigger記述を直して再検証する。補正不能なら、呼べなかったagent、足りないtrigger、必要なrepo-localまたは共通skill側の修正案を `blocked` として返す。

## 仮想実行

1. 親Main Agentが `workflow_audit_virtual_main` subagentを起動する。
   - `fork_context: false` を原則とする。
   - 親Main Agentの途中思考や採用案ではなく、一時worktree path、scenario要件、Expected Subagent Coverage、禁止事項、repo-local supplement候補、出力契約だけを渡す。
   - `workflow_audit_virtual_main` は仮想Main Agentとして、下位subagentを `subagent-orchestration` で呼び出してよいことを明記する。
2. `workflow_audit_virtual_main` が、一時worktree内で `$wf-explore` を実行する。
   - repo-local supplementを読み、必要なprep scoutを `subagent-orchestration` で呼び出す。
   - 人間判断が必要な点は、audit目的に限り第一候補を仮採用する。
   - `prep_status: ready` の計画を作る。
3. `workflow_audit_virtual_main` が、`wf-explore` の計画に対し、audit目的の仮想承認を与える。
   - 仮想承認は本番仕様やrisk acceptanceではない。
   - security、privacy、release、本番操作のrisk acceptanceが必要な計画は、シナリオ不適として別シナリオへ切り替える。
4. `workflow_audit_virtual_main` が、仮想承認済み計画をauthorityとして `$wf-implement` を実行する。
   - docs / 実装 / test の変更を必ず発生させる。
   - formatter、linter、test、build、typecheck、E2Eは実行しない。
   - `wf-verify` は `test_runner` へ委譲するが、実コマンドは実行せず `not_run` 証跡を返すように委譲する。
   - 同一 `wf-implement` 実行中に `wf-verify` を複数回呼ぶ場合は、最初の `test_runner` session idを保持し、以後は同じsessionへ追加packetを送る。新sessionが必要な場合は許可された例外理由をWorkflow Traceへ残す。
   - `audit-docs` は `project_doc_auditor` へ委譲する。
   - `wf-review` はrepo-local reviewable gate実装へ委譲または照合する。
5. 親Main Agentが、Workflow Traceを回収して評価する。

## Virtual Main Agent Delegation Packet

親Main Agentが `workflow_audit_virtual_main` を起動するときは、次の形で渡す。

```md
Agent: workflow_audit_virtual_main
fork_context: false

Scope:
- Work only inside: <temp worktree path>
- Treat this subagent as the virtual Main Agent for audit-workflow.
- You may use subagent-orchestration for lower-level subagents.

Goal:
- Run the audit-workflow virtual scenario from wf-explore through wf-review.
- Use a scenario that necessarily changes docs, implementation, and tests.
- Return Workflow Trace and findings.

Do not:
- Do not modify the original worktree.
- Do not run formatter, linter, test, build, typecheck, E2E, network install, DB access, production operation, secret access, or destructive command.
- Do not treat virtual approval as real product approval or risk acceptance.
- Do not let lower-level subagents ignore subagent-execution.

Evidence:
- Temp worktree path:
- Repo-local supplement candidates:
- Included uncommitted changes:
- Scenario requirements:
- Expected Subagent Coverage:
- Reusable session rules:
  - Preserve the first test_runner session id during one wf-implement execution.
  - Reuse that session for repeated wf-verify calls unless stale diff, stale checkout, broken environment state, wrong assumptions, another task, another branch, or another worktree applies.
  - Record session ids and any new-session exception reason.
- Output format:

Deliver:
- Workflow Trace
- temp worktree diff summary
- gate results
- subagent coverage matrix
- findings classified as repo-local / common-skill / human-decision

Done when:
- wf-explore, virtual approval, wf-implement, wf-verify, audit-docs, and wf-review have been attempted in the temp worktree, or a blocker prevents that attempt.
- Every subagent listed in Expected Subagent Coverage has been called, or a blocker explains why coverage is impossible.
- No forbidden command was executed.
```

## Workflow Trace

仮想Main Agentは、検証結果に次を必ず含める。

```md
# Workflow Trace

## Scenario
- summary:
- docs changed:
- implementation changed:
- tests changed:

## Used Skills
- wf-explore:
- wf-implement:
- wf-verify:
- audit-docs:
- wf-review:
- scaffold / audit repairs:

## Subagents
- agent:
  role:
  session_id:
  previous_session_id:
  session_reused: true / false / not_applicable / unknown
  new_session_reason:
  expected: yes / no
  called by workflow:
  trigger covered: yes / no
  delegation packet complete: yes / no
  result: done / blocked
  evidence summary:

## Expected Subagent Coverage
- agent:
  role:
  expected workflow:
  trigger condition:
  expected session count:
  actual session ids:
  reused/new:
  new-session exception reason:
  called: yes / no
  if not called:
  coverage finding:

## Verification Commands
- command:
  expected owner:
  executed: no
  reason: audit-workflow forbids real formatter / linter / test execution
  evidence:

## Gate Results
- prep_status:
- execution_status:
- verification_status:
- audit_status:
- review_status:

## Findings
- finding:
  cause:
  fix:
  fix scope: repo-local / common-skill / human-decision
  severity: blocking / non-blocking
```

## 評価

次を確認する。

- `wf-explore` で調査、計画、作業コンテクストMarkdown、state file、Decision Clarification が作られたか。
- `workflow_audit_virtual_main` subagentが起動され、親Main Agentが `wf-*` 検証を直接実行していないか。
- `Expected Subagent Coverage` が作られ、repo-localで定義された呼び出し候補subagentが漏れなく列挙されたか。
- coverage taskが `Expected Subagent Coverage` の全subagentを呼ぶように設計されたか。
- `wf-explore` でrepo-local prep scoutが必要な場合に呼び出されたか。未整備なら補正または明確なfindingになったか。
- 仮想承認が計画にだけ適用され、security、privacy、release、本番操作の判断を確定していないか。
- `wf-implement` で docs / 実装 / test がすべて変更されたか。
- formatter、linter、test、build、typecheck、E2Eを実行していないか。
- `wf-verify` がrepo内 `test_runner` に委譲され、実コマンド未実行の証跡とstate fileのcommandsへ反映できる結果を返したか。
- 同一 `wf-implement` 実行中の複数回 `wf-verify` で、最初の `test_runner` session idが保持され、許可された例外がない限り同じsessionへ再委譲されたか。
- `test_runner` が複数sessionになった場合、古いdiff、古いcheckout、壊れた環境状態、誤った前提、別task、別ブランチ、別worktreeのいずれかの理由がWorkflow Traceに残っているか。
- Workflow Traceと `Expected Subagent Coverage` に、下位subagentの `session_id` または `agent_id` が記録されているか。idがない場合、coverageはrecall behaviorを立証できないfindingとして扱う。
- `audit-docs` が `project_doc_auditor` に委譲されたか。
- `wf-review` がrepo-local reviewable gate実装を使ったか。
- specialist reviewerやrepo-local reviewerが複数ある場合に、すべてroutingされたか。
- `Expected Subagent Coverage` の中に呼ばれていないagentが残った状態で `pass` にしていないか。
- すべての下位subagent呼び出しが `subagent-orchestration` のDelegation Packetを使い、下位subagentに `subagent-execution` を守らせたか。
- repo-local不足が scaffold / audit 系skillで補正できる場合に、同じ作業内で修正して再検証したか。
- 共通skill側の不足をrepo-local修正で隠していないか。

## 自己改善

findingは次に分類する。

- `repo-local-auto-fixable`: `AGENTS.md`、docs、`.codex/skills`、`.codex/agents`、repo-local workflow supplementの修正で完走に近づくもの。
- `needs-scaffold`: `scaffold-project`、`scaffold-agent-prep-scout`、`scaffold-agent-test-runner`、`scaffold-agent-reviewer` で補正できるもの。
- `needs-audit`: `audit-docs`、`audit-repo-skill` で補正できるもの。
- `common-skill-blocked`: 共通skill本体の不足、矛盾、誤記、入力契約不足が原因のもの。
- `human-decision`: 仕様、security、privacy、release、risk acceptance、破壊的操作の判断が必要なもの。

`repo-local-auto-fixable`、`needs-scaffold`、`needs-audit` は同じ作業内で修正してよい。修正後は一時worktreeを作り直して再検証する。再検証は最大2回まで行う。

`common-skill-blocked` は修正せず、対象skill名、該当箇所、完走を止めた理由、修正案を報告する。

`human-decision` は `$idiot` へ渡せる形で、判断質問へ整理する。

## 終了条件

- `pass`: 2回以内の自己改善で、docs / 実装 / test を伴う架空タスクが、実コマンド未実行制約を守ったまま `wf-explore` から `wf-review` まで完走した。
- `findings-fixed`: repo-local修正を適用し、最終再検証で完走した。
- `blocked`: 共通skill側の不足、人間判断、patch適用失敗、git worktree作成失敗、シナリオ作成不能、または2回以内に完走できない問題が残った。

`pass` と `findings-fixed` は、`Expected Subagent Coverage` の全subagentが呼ばれた場合だけ使える。呼ばれていないagentが1つでも残り、補正や再検証でも解消できない場合は `blocked` とする。

同一 `wf-implement` 実行中に複数の `test_runner` sessionが観測され、許可された例外理由がない場合は `pass` / `findings-fixed` にしない。下位subagentのsession idがTraceに欠け、再利用されたか判定できない場合も、少なくともaudit findingとして扱う。

`blocked` の場合でも、まず完走を試みたWorkflow Trace、補正済み内容、残った原因、次の戻り先を報告する。

`pass` または `findings-fixed` の場合、一時worktreeの架空変更は検証用の消耗品として扱う。Workflow Traceと差分要約を回収した後、一時worktreeは削除済みであることを終了条件に含める。

## 出力形式

固定のaudit reportテンプレートを会話上に出さない。ユーザーが見るべき主対象は、repo-localに適用された修正差分と、一時worktreeで観測された完走可否である。

保存用のaudit reportをユーザーが求めた場合だけ、目的に合う範囲で次を残す。

- scenario、反復回数、最終状態
- Workflow Traceの要約
- 呼び出されたsubagentとExpected Subagent Coverage
- 適用したrepo-local修正
- 共通skill側blockerと修正案
- human decision
- cleanup結果

## 禁止事項

- git管理されていないrepoで検証を進めない。
- 一時worktreeの架空変更を本体worktreeへ混ぜない。
- 親Main Agentが `workflow_audit_virtual_main` subagentを起動せずに、架空タスクの `wf-*` 検証を直接実行しない。
- formatter、linter、test、build、typecheck、E2E、外部network、package install、DB接続、本番操作、secret参照、破壊的コマンドを実行しない。
- 検証コマンド未実行を隠して `verified` 扱いにしない。
- `wf-review` をMain Agentが証跡なしに代替判定しない。
- repo-local不足を共通skill問題として報告しない。
- 共通skill側の不足をrepo-local修正で隠さない。
- repo-localで定義されたreview系subagentが複数あるのに、1種類だけ呼んでcoverage完了扱いにしない。
- `Expected Subagent Coverage` に未呼び出しagentが残っている状態で `pass` または `findings-fixed` にしない。
- human decisionが必要な事項を第一候補で本採用しない。
- `pass` または `findings-fixed` で、架空差分が残っていることだけを理由に一時worktreeを保全しない。
- `blocked` で、原因再現に必要な未回収の一時worktree差分をcleanup前に捨てない。

## 完了報告

最後は、修正差分と再実行判断に必要な情報だけを自然に返す。

- 最終状態: `pass` / `findings-fixed` / `blocked`
- 修正したrepo-localファイルと、何を変えたか。
- 人間がdiffで特に見るべきポイント。
- 呼び出せなかったsubagent、共通skill側blocker、human decision。
- 一時worktreeを残した場合だけ、そのpathと理由。

修正がない場合は、完走可否、残blocker、次の戻り先だけを短く返す。
