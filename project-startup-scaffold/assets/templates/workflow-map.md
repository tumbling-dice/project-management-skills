# Workflow Map

## 目的

共通project-management workflowとrepo内文書、成果物、停止条件を接続する。

## Map

| Situation | Use workflow | Input artifact | Output artifact | Stop condition | Human decision | Repo-local supplement |
| --- | --- | --- | --- | --- | --- | --- |
| 実装前に事実確認が必要 | `investigation-workflow` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| 実装計画を作る | `implementation-plan-gate` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| 計画承認後に実装する | `implementation-execution-workflow` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| 検証証跡を作る | `verification-workflow` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| レビュー前条件を見る | `reviewable-gate-review` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| review指摘を分類する | `post-review-fix-triage` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| 文書矛盾を点検する | `project-doc-consistency-audit` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |
| repo内skillやagentを点検する | `repo-skill-audit` | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |

## Repo-local Rules

- 要確認
