---
name: repo-workflow-migration-plan
description: ユーザーが自然文で、成熟済みrepo内の AGENTS.md、docs、repo-local skill、custom agent、review routing、検証手順、作業メモを、共通project-management workflowへ寄せるための削除・委譲・残置・分解・共通側不足の対応表を作りたいと頼んだ場合に使う。workflow-router のrouting結果、または $repo-workflow-migration-plan の明示でも使う。移行対象ファイルの修正や削除は行わず、移行計画、参照更新順、削除前確認、次workflowを整理する。
---

# Repo Workflow Migration Plan

このskillは、すでに運用しているrepo内のAI運用docs、repo-local skill、custom agent、review routing、検証手順を、共通project-management workflowへ寄せるための移行計画を作るworkflowです。目的は、既存資産を残すことではなく、共通workflowへ委譲できる部分とrepo固有制約として残す部分を分け、削除や更新の順序を人間が確認できる形にすることです。

## 使う場面

- repo-local operational skillを共通workflowへ統一したい。
- 過去docsや作業メモを、現在の共通workflow成果物やrepo固有補足へ置き換えたい。
- repo固有docsを分解し、共通側へ寄せる部分とrepo側へ薄く残す部分を分けたい。
- `repo-skill-audit` 後に、実際の削除、委譲、残置、参照更新の順序を決めたい。
- 共通側に足りない雛形やworkflow候補を、repo固有ルールへ変えずに提案したい。

## 使わない場面

- 文書の矛盾や古い前提だけを点検する場合。その場合は `project-doc-consistency-audit` を使います。
- repo内skill、agent、AGENTS、検証手順の危険な権限や配布性だけを点検する場合。その場合は `repo-skill-audit` を使います。
- 新規PJや文書が薄い既存PJの初期文書を作る場合。その場合は `project-startup-scaffold` を使います。
- コード変更の実装前調査と計画を作る場合。その場合は `implementation-prep-workflow` を使います。
- 実際にファイル削除、移動、編集、検証実行、review判定を行う場合。

## 入力

移行目的に応じて、次のうち関係するものを確認します。全件を機械的に読むのではなく、移行判断に関係する資産を優先します。

- `AGENTS.md`
- README、PJ文書、AI利用ルール、review docs、verification docs
- `docs/work/` の代表的な調査、計画、検証、review、handoff成果物
- `.codex/skills/*/SKILL.md`
- `.codex/agents/*`
- repo固有のrouting文書、作業メモtemplate、検証手順
- 共通workflow skill一覧と、repoで使う想定の共通skill

入力不足で移行判断ができない場合は、`migration_status: blocked` とし、不足している資産、人間判断、追加auditのどれが必要かを分けます。

## 判定分類

各資産は次のいずれかに分類します。

- `delete`: 共通workflowや別資産へ置換済みで、逆参照確認後に削除できる。
- `delegate-to-common`: 資産自体は残さず、共通skillや共通workflow成果物へ委譲する。
- `keep-repo-local`: repo固有の制約、コマンド、review観点、データ境界などとして薄く残す。
- `split`: 共通化できる部分とrepo固有で残す部分を分ける。
- `needs-common-template`: repo固有ではなく、複数repoで使える共通templateやworkflow候補として提案する。
- `blocked-human-decision`: AIだけでは削除、委譲、残置を決められない。

`keep-repo-local` は例外扱いです。残す場合は、どのrepo固有性があり、共通skillへ混ぜてはいけない理由を明記します。

## 手順

1. 移行目的、対象repo、対象資産、非対象範囲を確認する。
2. 現在の共通workflow受け皿を整理する。
   - `project-startup-scaffold`
   - `implementation-prep-workflow`
   - `implementation-execution-workflow`
   - `verification-workflow`
   - `reviewable-gate-review`
   - `post-review-fix-triage`
   - `workflow-artifact-handoff`
   - `decision-clarification-workflow`
   - `project-doc-consistency-audit`
   - `repo-skill-audit`
   - `test-runner-scaffold`
   - `specialist-reviewer-scaffold`
3. repo内資産を、目的、入力、出力、禁止事項、参照元、更新頻度で整理する。
4. 各資産を判定分類へ割り当て、理由、移行先、repo-local remainder、削除前guard、次workflowを付ける。
5. 参照更新順を作る。削除候補は、逆参照確認と代替先の明記が終わるまで削除可能扱いにしない。
6. 共通側不足は、repo固有のコマンド、reviewer名、文書名、アプリ固有ルールを含めず、一般化したtemplateやworkflow候補として書く。
7. 人間判断が必要な項目は、`decision-clarification-workflow` へ渡せる粒度へ絞る。
8. 移行計画を会話上またはPJ慣習の作業メモへ出力する。

## 出力先

ユーザーが「計画を残す」「作業メモへ出す」「後続workflowへ渡す」と依頼している場合は、PJ慣習に従って移行計画ファイルを作ります。慣習がなければ、共有用の成果物として `docs/work/<task-id>-repo-workflow-migration.md` を推奨します。

ユーザーが会話上の整理だけを求めた場合、または対象repoのファイル更新を避けたい場合は、ファイルを作らず会話上に出力します。どちらの場合も、移行対象ファイルの削除、移動、編集はこのskill内では行いません。

## 出力形式

```md
# Repo Workflow Migration Plan

## Status

migration_status: ready / blocked

## Scope

- repo:
- target assets:
- common workflow baseline:
- not in scope:

## Common Workflow Map

- repo need:
  common workflow:
  boundary:
  repo-local supplement:

## Asset Decisions

- asset:
  type: doc / skill / custom-agent / AGENTS / verification / review-routing / work-template
  decision: delete / delegate-to-common / keep-repo-local / split / needs-common-template / blocked-human-decision
  reason:
  replacement:
  repo-local remainder:
  references to update:
  deletion guard:
  next workflow:

## References To Update

- file:
  current reference:
  replacement:

## Deletion Order

- step:
  assets:
  guard:

## Repo-local Remains

- asset:
  reason:
  minimal content:

## Common-side Gaps

- gap:
  why common:
  proposed common artifact:
  must not include:

## Blocked Human Decisions

- decision:
  why blocking:
  options:
  recommended default:

## Next Workflow

- repo update:
- common skill update:
- audit:
- human decision:
```

## 禁止事項

- 移行対象repoのファイル削除、移動、編集、整形をこのskill内で行わない。
- 逆参照確認なしに資産を削除可能と判定しない。
- 既存資産を残すことを目的化しない。残す場合はrepo固有性を明記する。
- repo固有の検証コマンド、reviewer名、app固有ルールを共通skillへ混ぜない。
- 文書矛盾audit、repo skill audit、実装計画、検証実行、review判定をこのskill内で代替しない。
- secrets、credential、本番ログ、生の顧客データを移行計画へ複製しない。
- AIの判断だけでrelease、merge、本番操作、risk acceptanceを承認しない。

## 完了報告

最後に次を報告します。

- `migration_status`
- 移行計画の出力先
- `delete` / `delegate-to-common` / `keep-repo-local` / `split` の件数
- 削除前に確認する逆参照
- 共通側不足の提案数
- 人間判断が必要な項目
- 次workflow
