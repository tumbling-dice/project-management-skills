---
name: repo-skill-audit
description: ユーザーが自然文で、repo内の AGENTS.md、.codex/skills、.codex/agents、review routing、検証手順の整合、公開前確認、役割重複、ローカルフルパス、古い検証コマンド、危険な権限や禁止操作漏れを点検したいと頼んだ場合に使う。workflow-router のrouting結果、または $repo-skill-audit の明示でも使う。修正は行わず、必要な更新候補と戻り先を整理する。
---

# Repo Skill Audit

このskillは、repo内のAI利用ルール、repo固有skill、custom agent、review routing、検証手順を点検するためのauditワークフローです。目的は、共通skillとrepo固有skillの役割境界、配布性、安全条件、workflow接続を確認し、修正すべき候補を整理することです。

## 使う場面

- `.codex/skills` や `.codex/agents` を追加した後に整合を確認したい。
- 共通skill更新後、repo内skillやAGENTS.mdが古くなっていないか見たい。
- GitHub公開前に、ローカルフルパス、secret、環境依存の記述を点検したい。
- reviewable gate、specialist reviewer、test_runner、verification手順のroutingを確認したい。
- repo内skillが増え、重複や責務の混線を整理したい。

## 使わない場面

- audit結果を実装修正する場合。
- 検証コマンドを実行する場合。
- review判定や専門reviewを行う場合。
- 新しいrepo内skillやagentをscaffoldする場合。その場合は該当するscaffold skillを使います。

## 入力

確認対象はrepoの慣習に従います。一般には次を読みます。

- `AGENTS.md`
- `.codex/config.toml`
- `.codex/skills/*/SKILL.md`
- `.codex/agents/*`
- `docs/review/`
- `docs/verification/`
- `docs/work/` の代表的な成果物
- CI workflow、project manifest、検証script

すべてを深掘りする必要はありません。audit目的に関係するファイルを優先し、対象外は記録します。

## Audit観点

### 役割境界

- 共通skillとrepo固有skillの責務が重複しすぎていないか。
- `test_runner` が修正やreview判定を担当していないか。
- specialist reviewerが検証実行や実装修正を担当していないか。
- reviewable gateがrepo固有の深い設計判断を単独で承認していないか。

### Workflow接続

- `investigation-workflow`、`implementation-plan-gate`、`implementation-execution-workflow`、`verification-workflow`、`reviewable-gate-review` への戻り先が明確か。
- `decision-clarification-workflow` へ渡す人間判断が整理されているか。
- `post-review-fix-triage` や `workflow-artifact-handoff` が必要な場面がないか。

### 配布性

- 個人ホームディレクトリ、一時ディレクトリ、個人checkout先などのローカルフルパスがskill本文や公開文書に固定されていないか。
- 別skillの資材を参照する時に、skill名と `assets/...`、`references/...`、`scripts/...` など相対的なasset名で表しているか。
- repo固有コマンドが共通skill側へ混入していないか。

### 検証と権限

- 検証コマンドのsource of truthが明確か。
- snapshot、golden、fixture再生成、依存関係更新、migration、deployが暗黙実行されないか。
- sandbox権限、network、secret、外部service、GUI、localhost、artifact、timeoutの扱いが明記されているか。
- 実行していない検証を実行済み扱いしない出力形式になっているか。

### セキュリティと公開前確認

- secrets、credential、本番DB接続情報、本番ログの生データが含まれていないか。
- auth、permission、tenant、PII、secret、ログ、外部入力を扱うskillに確認観点と人間判断の戻り先があるか。
- release、merge、本番操作、risk acceptanceをAIが承認する記述がないか。

## 手順

1. audit目的と対象範囲を確認する。
2. 対象ファイルを列挙し、読む優先度を決める。
3. Audit観点ごとに finding を記録する。
4. findingを severity と戻り先で分類する。
5. 修正候補を、実装せずに提案する。
6. 必要なら `docs/work/<task-id>-repo-skill-audit.md` にaudit結果を保存する。

## Severity

- `blocking`: 公開、運用、またはworkflow実行を止めるべき問題。
- `high`: 次に該当skillやagentを使う前に直すべき問題。
- `medium`: 近いうちに直すと混乱を減らせる問題。
- `low`: 表記、整理、重複削減など。

## 出力形式

```md
# Repo Skill Audit

## Status

audit_status: pass / findings / blocked

## Scope

- repo:
- target files:
- not checked:
- reason:

## Findings

- id:
  severity: blocking / high / medium / low
  category: role-boundary / workflow-routing / distribution / verification / security / documentation
  file:
  summary:
  evidence:
  impact:
  recommended fix:
  next workflow:

## Positive Checks

- check:
  evidence:

## Open Questions

- question:
  why it matters:
  next owner:

## Suggested Update Order

- step:
  reason:

## Next Step

- no action / skill update / agent update / AGENTS.md update / verification-workflow / test-runner-scaffold / specialist-reviewer-scaffold / decision-clarification-workflow / human decision
```

## 禁止事項

- audit中に実装修正、skill修正、agent修正、検証実行を始めない。
- secretsや本番ログを本文へ複製しない。
- ローカル環境にだけ存在するpathを公開前提の推奨として固定しない。
- severityを曖昧にせず、影響と戻り先を明記する。
- ユーザー承認なしに破壊的操作、削除、整形、移動を行わない。

## 完了報告

最後に次を報告します。

- `audit_status`
- blocking / high findingの有無
- 主要findingと推奨更新順
- 未確認範囲
- 次の戻り先
