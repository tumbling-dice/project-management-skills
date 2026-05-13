---
name: audit-workflow
description: ユーザーが自然文で、repo内ドキュメントやAGENTS.mdで定義された wf-* 系workflowが、git worktreeと仮想Main Agentで完走できるか検証し、scaffold / audit 系skillで補正できるrepo-local不足は同じ作業内で自己改善したいと頼んだ場合に使う。共通skill側の不足で完走できない場合はblockedとして修正案を返す。$audit-workflow の明示でも使う。
---

# audit-workflow

このskillは、repo内の `AGENTS.md`、docs、repo-local skill、custom agent、review routing、検証手順が、`wf-explore` から `wf-implement`、`wf-verify`、`audit-docs`、`wf-review` までの実運用に耐えるかを、一時 `git worktree` と仮想Main Agentで検証するためのworkflowである。

目的は、workflow資材を読むだけの静的点検ではなく、docs / 実装 / test が必ず変更される架空タスクを使って、計画、仮想承認、実装、検証委譲、文書audit、reviewable gate まで完走できる状態へ repo-local 資材を自己改善することである。

## 使う場面

- repo内のAI workflow、`AGENTS.md`、workflow map、repo-local skill、custom agentが、`wf-*` 系workflowで想定通りに使われるか検証したい。
- `test_runner`、prep scout、reviewable gate、specialist reviewer、`project_doc_auditor` との接続不足を、実行シナリオで発見したい。
- scaffold / audit 系skillで補正できるrepo-local不足を同じ作業内で修正し、再検証したい。
- 共通skill側の仕様不足、矛盾、表現不足により完走できない箇所を、repo-local修正と分けて報告したい。

## 使わない場面

- 実際のプロダクト変更を進める場合。その場合は `wf-explore` から始める。
- 単なるrepo-local skill / agentの静的点検だけをしたい場合。その場合は `audit-repo-skill` を使う。
- PJ文書群の矛盾だけを点検したい場合。その場合は `audit-docs` を使う。
- repo固有の `test_runner` やreviewerを最初から作る依頼だけの場合。その場合は該当する `scaffold-*` skillを使う。

## 原則

- 対象がgit repoでない場合は `audit_status: blocked` とする。
- 一時 `git worktree` で検証し、検証中の架空変更を本体worktreeへ混ぜない。
- 本体worktreeに未コミット差分がある場合は、対象差分をpatchとして一時worktreeへ持ち込む。patch作成または適用に失敗した場合は `blocked` とし、失敗理由と未適用pathを返す。
- このskillを実行するagentは仮想Main Agentとして扱う。`subagent-execution` の対象外であり、`subagent-orchestration` を使って下位subagentを呼び出せる。
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
   - `docs/ai/`
   - `docs/review/`
   - `docs/verification/`
   - `docs/work/`
   - repo固有のworkflow map
4. `wf-explore` で使うprep scout、`wf-verify` で使う `test_runner`、`audit-docs` の `project_doc_auditor`、`wf-review` のreviewable gate実装、専門reviewer routingがあるか確認する。
5. 既知のrepo-local不足が明白で、scaffold / audit 系skillで補正できる場合は、本検証前に必要最小限だけ修正してよい。

## 一時worktree

1. 一時worktreeを作成する。
2. 本体worktreeの未コミット差分をpatchとして一時worktreeへ適用する。
3. 一時worktree内でだけ架空タスクの `wf-*` 検証を行う。
4. 検証後、一時worktreeの差分、作業メモ、Workflow Trace、blocked理由、未実行検証証跡を回収する。
5. cleanupに失敗した場合は、残ったworktree path、理由、手動削除可否を報告する。未回収の差分がある場合は削除せず、差分要約を残す。

## シナリオ要件

架空タスクは固定fixtureでもrepoに合わせた生成でもよい。ただし、必ず次を満たす。

- docsを修正する必要がある。
- 実装ファイルを修正する必要がある。
- testを追加または更新する必要がある。
- 検証コマンド候補が存在し、実行せず `not_run` 証跡として扱える。
- repo-local review routingまたはreviewable gateの入力証跡を作れる。

repoに実装やtestが存在しない場合は、`scaffold-project`、`scaffold-agent-test-runner`、`scaffold-agent-reviewer`、`audit-repo-skill` などで補正できるか確認する。補正後も docs / 実装 / test を伴うシナリオを作れない場合は `blocked` とする。

## 仮想実行

1. 仮想Main Agentとして、一時worktree内で `$wf-explore` を実行する。
   - repo-local supplementを読み、必要なprep scoutを `subagent-orchestration` で呼び出す。
   - 人間判断が必要な点は、audit目的に限り第一候補を仮採用する。
   - `prep_status: ready` の計画を作る。
2. `wf-explore` の計画に対し、audit目的の仮想承認を与える。
   - 仮想承認は本番仕様やrisk acceptanceではない。
   - security、privacy、release、本番操作のrisk acceptanceが必要な計画は、シナリオ不適として別シナリオへ切り替える。
3. 仮想承認済み計画をauthorityとして `$wf-implement` を実行する。
   - docs / 実装 / test の変更を必ず発生させる。
   - formatter、linter、test、build、typecheck、E2Eは実行しない。
   - `wf-verify` は `test_runner` へ委譲するが、実コマンドは実行せず `not_run` 証跡を返すように委譲する。
   - `audit-docs` は `project_doc_auditor` へ委譲する。
   - `wf-review` はrepo-local reviewable gate実装へ委譲または照合する。
4. Workflow Traceを回収する。

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
  called by workflow:
  delegation packet complete: yes / no
  result: done / blocked
  evidence summary:

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

- `wf-explore` で調査、計画、作業コンテクスト、Decision Clarification が作られたか。
- `wf-explore` でrepo-local prep scoutが必要な場合に呼び出されたか。未整備なら補正または明確なfindingになったか。
- 仮想承認が計画にだけ適用され、security、privacy、release、本番操作の判断を確定していないか。
- `wf-implement` で docs / 実装 / test がすべて変更されたか。
- formatter、linter、test、build、typecheck、E2Eを実行していないか。
- `wf-verify` がrepo内 `test_runner` に委譲され、実コマンド未実行の証跡を返したか。
- `audit-docs` が `project_doc_auditor` に委譲されたか。
- `wf-review` がrepo-local reviewable gate実装を使ったか。
- specialist reviewerやrepo-local reviewerが必要な場合にroutingされたか。
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

`human-decision` は `$idiot` へ渡せる形で、少数の判断質問へ整理する。

## 終了条件

- `pass`: 2回以内の自己改善で、docs / 実装 / test を伴う架空タスクが、実コマンド未実行制約を守ったまま `wf-explore` から `wf-review` まで完走した。
- `findings-fixed`: repo-local修正を適用し、最終再検証で完走した。
- `blocked`: 共通skill側の不足、人間判断、patch適用失敗、git worktree作成失敗、シナリオ作成不能、または2回以内に完走できない問題が残った。

`blocked` の場合でも、まず完走を試みたWorkflow Trace、補正済み内容、残った原因、次の戻り先を報告する。

## 出力形式

```md
# Workflow Audit Report

## Status
audit_status: pass / findings-fixed / blocked

## Scope
- repo:
- base ref:
- included uncommitted changes: yes / no
- scenario:

## Iterations
- iteration:
  result:
  findings:
  repairs applied:
  rerun reason:

## Workflow Trace Summary
- used skills:
- subagents:
- docs changed:
- implementation changed:
- tests changed:
- verification commands not run:
- gate results:

## Applied Repo Fixes
- file:
  reason:
  source workflow:

## Common Skill Blockers
- skill:
  issue:
  evidence:
  suggested fix:

## Human Decisions
- decision:
  why blocking:
  options:
  recommended default:

## Cleanup
- temp worktree:
- cleanup result:
- remaining path:

## Next Step
- human review / audit-workflow rerun / audit-repo-skill / scaffold-agent-test-runner / scaffold-agent-reviewer / scaffold-agent-prep-scout / common skill update / human decision
```

## 禁止事項

- git管理されていないrepoで検証を進めない。
- 一時worktreeの架空変更を本体worktreeへ混ぜない。
- formatter、linter、test、build、typecheck、E2E、外部network、package install、DB接続、本番操作、secret参照、破壊的コマンドを実行しない。
- 検証コマンド未実行を隠して `verified` 扱いにしない。
- `wf-review` をMain Agentが証跡なしに代替判定しない。
- repo-local不足を共通skill問題として報告しない。
- 共通skill側の不足をrepo-local修正で隠さない。
- human decisionが必要な事項を第一候補で本採用しない。
- cleanup前に未回収の一時worktree差分を捨てない。

## 完了報告

最後に次を報告する。

- `audit_status`
- 検証した架空タスク
- 未コミット差分を持ち込んだか
- 実行した反復回数
- 使用された `wf-*` skill と scaffold / audit 系skill
- 呼び出されたsubagentと結果
- docs / 実装 / test が変更された証跡
- 実行しなかった検証コマンドと理由
- 適用したrepo-local修正
- 共通skill側のblockerと修正案
- human decisionの有無
- 一時worktree cleanup結果
