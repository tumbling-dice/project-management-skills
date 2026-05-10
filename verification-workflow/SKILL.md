---
name: verification-workflow
description: このskillは workflow-router のrouting結果、またはユーザーが $verification-workflow を明示した場合だけ使う。通常依頼から直接発火しない。実PJでは Main Agent が直接実行せず、repo内にscaffoldされた test_runner custom agentへ委譲する。実装後またはreviewable gate前に、承認済み計画、差分、変更ファイル、repo固有の検証手順をもとに検証範囲を確定し、検証結果を証跡として整理する。修正、テスト更新、review判定は行わない。
---

# Verification Workflow

このskillは、実装後の検証を計画どおりに実行または委譲し、`reviewable-gate-review` に渡せる証跡へ整理するための共通ワークフローです。具体的な検証コマンドはrepo内の手順、script、CI、または承認済み計画をsource of truthにします。

## 実行形態

実PJでは、Main Agentがこのskillを直接実行してはいけません。必ずrepo内にscaffoldされた `test_runner` custom agentへ委譲して実行します。

- Main Agentがこのskillを読んだ場合は、自分で検証範囲決定や検証コマンド実行をせず、承認済み計画、差分、変更ファイル、追加/更新テスト、repo固有検証手順、非対象範囲を短くまとめてrepo内 `test_runner` へ渡します。
- repo内 `test_runner` custom agentが使えない場合は、`verification_status: blocked` とし、`$test-runner-scaffold` へ戻します。
- 実PJでは、同一Main Agentによる代替verificationを行いません。代替verificationは、このskill自体の開発・検証で明示された場合だけ行います。
- `test_runner` は、repo内検証手順に従って検証範囲、コマンド実行、結果分類、戻り先整理、証跡作成を担当します。

## 目的

`verification-workflow` は、実装者の自己申告だけで「検証済み」と扱わないための入口です。検証対象、実行コマンド、実行者、結果、未実行理由、失敗時の戻り先を明確にします。

このskillは次を担当します。

- 承認済み計画と差分から、必要な検証範囲を確認する。
- repo固有の検証手順から、実行するコマンドを確定する。
- repo内 `test_runner` が、`subagent-orchestration` に従って検証を実行する。
- 検証結果、artifact、warning、未実行理由を証跡として整理する。
- 失敗や未実行がある場合に、次の戻り先を決める。

## 使う場面

- 実装後に、計画された検証コマンドを `test_runner` へ委譲したい。
- `reviewable-gate-review` へ渡す検証証跡を整理したい。
- test、lint、build、typecheck、E2E、smoke、visual確認などの実行結果をまとめたい。
- 検証失敗、権限不足、環境不備、未実行検証を分類したい。
- repo内 `test_runner` に検証コマンド実行を任せたい。

## 使わない場面

- 検証失敗を修正する場合。
- テストやsnapshotを更新する場合。
- 検証専用の `test_runner` custom agentを作る場合。その場合は `$test-runner-scaffold` を使います。
- 差分がreview可能か判定する場合。その場合は `reviewable-gate-review` を使います。
- 実装前に検証コマンドを計画する場合。その場合は `implementation-plan-gate` を使います。

## 基本方針

- 検証範囲は、承認済み計画、差分、repo固有の検証手順から決める。
- 検証コマンドを共通skillへ固定しない。
- 検証workflowは repo内 `test_runner` への委譲を必須とする。
- `test_runner` への委譲は `subagent-orchestration` に従う。
- repo内 `test_runner` が未整備の場合は、Main Agentが代替実行せず、`verification_status: blocked` として `$test-runner-scaffold` へ戻す。
- 検証失敗をこのskillで修正しない。
- snapshot更新、golden更新、fixture再生成、依存関係更新、migration、deploy、外部service操作は、検証として暗黙実行しない。

## 入力

最低限、次を確認します。

- 承認済み実装計画、または人間が承認した変更範囲
- git diff
- 変更ファイル一覧
- 追加または更新したテスト
- 計画された検証コマンド
- repo固有の検証手順、CI、script、既存の開発用コマンド
- 非対象範囲
- 権限、secret、外部service、dev server、localhost、artifactに関する注意点

入力が不足して検証範囲を決められない場合は、検証を推測で広げず `verification_status: blocked` として不足物を列挙します。

削除済みファイル、過去のdiff内にだけ見える計画、会話内で承認済みだと確認できない古い計画は、現行の承認済み入力として扱いません。参考観測として記録してもかまいませんが、それだけを根拠に検証範囲を確定しません。

## 出力先

ユーザーが「検証証跡を作る」「reviewable-gate-review に渡す」「作業メモへ残す」と依頼している場合は、検証証跡のファイル作成または更新を優先します。ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力します。

出力先はPJの慣習に従います。慣習がなければ、共有する検証証跡として `docs/work/<task-id>-verification.md` を推奨します。入力が `docs/work/<task-id>-implementation-plan.md` の実装計画なら、同じ `task-id` を使って検証証跡だと分かる名前にします。

`task-id` やファイル名が指定されていない場合は、承認済み計画、変更内容、または入力ファイル名から短い kebab-case 名を付けます。命名だけで停止しません。既存ファイルと衝突する場合は上書きせず、別名にするかユーザーへ確認します。

この命名と出力先選択は既定動作です。出力名が指定されていないこと、または証跡ファイル作成が明示されていないが `reviewable-gate-review` へ渡す依頼があることだけを理由に `blocked`、`不明瞭点`、完了報告の迷った点を増やしません。

## 手順

1. 承認済み計画と差分を照合する。
   - 変更が計画範囲に収まっているか
   - テスト追加や更新が計画と対応しているか
   - 非対象範囲へ踏み込んでいないか
2. repo固有の検証手順を確認する。
   - `.codex/skills/*verification*/SKILL.md`
   - `docs/verification/`
   - CI workflow
   - project manifest
   - build / test / lint / typecheck / E2E / visual確認の設定
3. 検証コマンドを分類する。
   - 今回必須の検証
   - 追加で推奨する検証
   - 時間や環境により任意の検証
   - 権限昇格、人間承認、外部service、secretが必要な検証
   - 実行してはいけない操作
4. 実行方法を決める。
   - repo内 `test_runner` がある場合は、必ず委譲する。
   - `test_runner` がない場合は、Main Agentが直接実行せず、`$test-runner-scaffold` を提案して `blocked` にする。
5. 検証workflowを `test_runner` へ委譲する。
6. 結果、ログ要約、artifact、warning、未実行理由をまとめる。
7. 失敗や未実行を分類し、次の戻り先を決める。
8. `reviewable-gate-review` へ渡せる証跡を出力する。

## `test_runner` への委譲

repo内に `.codex/agents/test_runner.toml` がある場合は、`subagent-orchestration` の Delegation Packet を使います。委譲文には、最低限次を含めます。

- `Agent`: `test_runner`
- `fork_context`: 原則 `false`
- `Scope`: 検証対象の差分、対象外、変更ファイル
- `Goal`: 指定された検証を実行し、結果証跡を返す
- `Do not`: 修正、テスト更新、snapshot更新、依存関係更新、migration、deploy、未指定検証の実行
- `Evidence`: command、reason、timeout、expected success、known warning、artifact、必要なログ範囲、権限要否
- `Deliver`: 実行結果、未実行理由、失敗分類、artifact、warning
- `Done when`: 指定検証が完了する、または権限や環境不足で続行不能と判断できる

`test_runner` の結果が `blocked` の場合、Main Agentは不足情報、権限、scope、環境前提を補えるか判断します。同じscopeを根拠なく二重委譲しません。

## 検証結果の分類

検証結果は次に分類します。

- `pass`: 必須検証が通過し、未実行検証のリスクがない、または理由が許容できる。
- `fail`: 検証が失敗し、実装差分またはテスト期待値の修正が必要。
- `blocked`: コマンド不明、権限不足、環境不足、scope不足、人間承認待ちにより検証できない。
- `partial`: 一部検証は通過したが、未実行検証や未確認artifactが残っている。

`pass` は「mergeしてよい」ではありません。`reviewable-gate-review` へ進めるための検証証跡が揃った状態を意味します。

## 失敗分類

失敗または未実行がある場合は、次のいずれかに分類します。

- 実装差分に起因する失敗
- テスト期待値、fixture、snapshot方針の不整合
- 検証コマンドや計画の不足
- 環境、依存関係、sandbox、権限不足
- 外部service、secret、network、dev server前提の不足
- flaky疑い
- 人間承認が必要な操作

分類できない場合は、追加調査が必要として扱います。

検証ログが短く、expected / actual やstack traceが十分に出ない場合は、ログだけで断定せず、承認済み計画、差分、変更ファイル、関連テストの期待値を補助根拠として分類します。その場合は `key log` に観測できた範囲を短く残し、`notes` に補助根拠を明記します。ログが薄いことだけを理由に `不明瞭点` や完了報告の迷った点を増やしません。

## 戻り先

検証結果に応じて戻り先を明記します。

- `pass`: `reviewable-gate-review`
- 実装差分に起因する失敗: `implementation-execution-workflow`
- テスト方針や検証範囲の不足: `implementation-plan-gate`
- 原因不明、再現条件不足、影響範囲不足: `investigation-workflow`
- 検証専用agentやrepo内検証手順が未整備: `$test-runner-scaffold`
- 権限、secret、外部service、破壊的操作、risk acceptance: human decision

## 出力形式

```md
# Verification Evidence

## Status

verification_status: pass / fail / blocked / partial

## Inputs

- plan:
- diff:
- changed files:
- tests:
- repo verification source:

## Required Verification

- command:
  reason:
  executor: test_runner / not_run
  expected:
  result:
  artifact:
  notes:

## Not Run

- command:
  reason:
  risk:
  next action:

## Failures

- command:
  classification:
  key log:
  likely next owner:

## Warnings

- なし / あり

## Next Step

- reviewable-gate-review / implementation-execution-workflow / implementation-plan-gate / investigation-workflow / test-runner-scaffold / human decision
```

## 禁止事項

- 検証失敗をこのskillで修正しない。
- 検証のためにテスト削除、skip、assertion弱体化をしない。
- snapshot更新、golden更新、fixture再生成を暗黙に実行しない。
- 実行していない検証を実行済みとして扱わない。
- コマンド不明のまま広い検証を推測実行しない。
- Main Agentが検証workflowや検証コマンドを直接実行しない。
- sandbox権限不足や環境不備を、根拠なく実装不具合として扱わない。
- release、merge、本番操作、リスク受容を承認しない。
- ファイルへ検証証跡を作成または更新する場合、shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。`apply_patch` を使う。

## 完了報告

最後に次を報告します。

- `verification_status`
- 実行または委譲したコマンド
- repo内 `test_runner` を使ったか
- 通過、失敗、未実行、warning
- artifactや重要ログ
- 次の戻り先
- `reviewable-gate-review` へ渡せる証跡が揃っているか
