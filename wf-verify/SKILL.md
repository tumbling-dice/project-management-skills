---
name: wf-verify
description: ユーザーが $wf-verify を明示した場合だけ使う。実PJでは Main Agent が直接実行せず、repo内にscaffoldされた test_runner custom agentへ委譲する。実装後またはreviewable gate前に、承認済み計画、差分、変更ファイル、repo固有の検証手順をもとに検証範囲を確定し、検証結果を証跡として整理する。修正、テスト更新、review判定は行わない。
---

# wf-verify

このskillは、実装後の検証を計画どおりに実行または委譲し、`wf-review` に渡せる証跡へ整理するための共通ワークフローである。具体的な検証コマンドのsource of truthはrepo内の手順、script、CIである。タスクごとの実行予定や実行結果は、承認済み計画と同じ `task-id` のstate fileがある場合は `commands` も入力にする。

このskillは、`$scaffold-agent-test-runner` で整備された repo-local `test_runner`、verification skill、検証手順、委譲契約を使う。`test_runner` のagent定義、Delegation Packet、repo固有コマンド分類、権限、artifact、timeoutの詳細はこのskillへ複製しない。

## 実行形態

実PJでは、Main Agentがこのskillを直接実行してはいけない。必ずrepo内にscaffoldされた `test_runner` custom agentへ委譲する。formatterやformat checkは、repo手順でMain Agent担当とされている場合だけこのworkflowの外側で実行し、その結果を入力証跡として渡す。

repo内 `test_runner` またはverification手順が使えない場合は、Main Agentが代替実行せず `verification_status: blocked` とし、`$scaffold-agent-test-runner` へ戻す。

## 目的

`wf-verify` は、実装者の自己申告だけで「検証済み」と扱わないための入口である。検証対象、実行コマンド、実行者、結果、未実行理由、失敗時の戻り先を明確にする。

このskillは次を担当する。

- 承認済み計画、差分、変更ファイル、追加または更新したテスト、非対象範囲を `test_runner` へ渡せる入力にまとめる。
- 検証結果、artifact、warning、未実行理由を証跡として整理する。
- 失敗や未実行がある場合に、次の戻り先を決める。

## 使う場面

- 実装後に、計画された検証コマンドを `test_runner` へ委譲したい。
- `wf-review` へ渡す検証証跡を整理したい。
- test、lint、build、typecheck、E2E、smoke、visual確認などの実行結果をまとめたい。
- 検証失敗、権限不足、環境不備、未実行検証を分類したい。
- repo内 `test_runner` に検証コマンド実行を任せたい。

## 使わない場面

- 検証失敗を修正する場合。
- テストやsnapshotを更新する場合。
- 検証専用の `test_runner` custom agentを作る場合。その場合は `$scaffold-agent-test-runner` を使う。
- 差分がreview可能か判定する場合。その場合は `wf-review` を使う。
- 実装前に検証コマンドを計画する場合。その場合は `wf-explore` を使う。

## 基本方針

- 検証範囲は、承認済み計画、差分、repo固有の検証手順から決める。
- 検証コマンドを共通skillへ固定しない。
- 検証workflowは repo内 `test_runner` への委譲を必須とする。
- 同一 `wf-implement` 実行中の再検証では、既存の `test_runner` sessionを原則として再利用する。
- formatterやformat checkは、repo手順でMain Agent担当とされている場合だけ例外としてこのworkflow外の入力証跡にする。
- repo内 `test_runner` が未整備の場合は、Main Agentが代替実行せず、`verification_status: blocked` として `$scaffold-agent-test-runner` へ戻す。
- 検証失敗をこのskillで修正しない。
- snapshot更新、golden更新、fixture再生成、依存関係更新、migration、deploy、外部service操作は、検証として暗黙実行しない。

## 入力

最低限、次を確認する。

- 承認済み実装計画、または人間が承認した変更範囲
- 承認済み計画と同じ `task-id` の `docs/work/<task-id>.state.json` があれば、その `commands`
- git diff
- 変更ファイル一覧
- 追加または更新したテスト
- 計画された検証コマンドまたはstate fileの `commands`
- repo固有の検証手順、CI、script、既存の開発用コマンド
- 非対象範囲
- 権限、secret、外部service、dev server、localhost、artifactに関する注意点
- 同一 `wf-implement` 実行中に取得済みの `existing_test_runner_session_id`
- `recall_policy`: `reuse-existing` / `first-run` / `new-session-with-reason`
- 新しいsessionが必要な場合の `new_session_reason`

入力が不足して検証範囲を決められない場合は、検証を推測で広げず `verification_status: blocked` として不足物を列挙する。

削除済みファイル、過去のdiff内にだけ見える計画、会話内で承認済みだと確認できない古い計画は、現行の承認済み入力として扱わない。参考観測として記録してもかまわないが、それだけを根拠に検証範囲を確定しない。

## Test Runner Session Lifecycle

`wf-implement` から呼ばれる場合、`wf-verify` は `test_runner` session lifecycle の証跡を返す。最初の検証では `existing_test_runner_session_id` が空でよい。`test_runner` を起動したら、作成された `executor_session_id` を返し、Main Agent が同じ `wf-implement` 実行中の再検証で保持できるようにする。

同一 `wf-implement` 実行中に `existing_test_runner_session_id` が渡された場合は、古いdiff、古いcheckout、壊れた環境状態、誤った前提、別task、別ブランチ、別worktreeのいずれかに該当しない限り、そのsessionへ追加の検証packetを送る。新しいsessionを作る場合は、許可された理由を `new_session_reason` に書く。

`existing_test_runner_session_id` があるのに新しいsessionを作り、`new_session_reason` がない場合は `verification_status: pass` にしない。検証そのものが実行済みでも、session lifecycle証跡が欠けているため `partial`、または検証統合に必要な情報が不足していれば `blocked` とする。

## 出力先

ユーザーが「検証証跡を作る」「wf-review に渡す」「作業コンテクストへ残す」と依頼している場合は、検証証跡のファイル作成または更新を優先する。ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力する。

出力先はPJの慣習に従う。慣習がなければ、共有する検証証跡として `docs/work/<task-id>-verification.md` を推奨する。入力が `docs/work/<task-id>-implementation-plan.md` の実装計画なら、同じ `task-id` を使って検証証跡だと分かる名前にする。

`task-id` やファイル名が指定されていない場合は、承認済み計画、変更内容、または入力ファイル名から短い kebab-case 名を付ける。命名だけで停止しない。既存ファイルと衝突する場合は上書きせず、別名にするかユーザーへ確認する。

この命名と出力先選択は既定動作である。出力名が指定されていないこと、または証跡ファイル作成が明示されていないが `wf-review` へ渡す依頼があることだけを理由に `blocked`、`不明瞭点`、完了報告の迷った点を増やさない。

## 手順

1. 承認済み計画、差分、変更ファイル、追加または更新したテスト、非対象範囲、formatter証跡を確認する。
2. repo-local verification手順と `test_runner` の入力契約を確認する。
3. `test_runner` へ検証を委譲する。`existing_test_runner_session_id` があり、例外理由がなければ、そのsessionへ追加packetを送る。初回または許可された例外では新しいsessionを起動する。委譲文の形式、権限、timeout、artifact、禁止操作はrepo-local手順に従う。
4. `test_runner` の結果、ログ要約、artifact、warning、未実行理由を検証証跡へまとめる。
5. state fileがある場合は、`commands` のstatus/resultへ反映できる形で実行結果を整理し、必要なら `test_runner_session_id`、`session_reused`、`new_session_reason` をnotesへ残す。
6. 失敗や未実行を分類し、次の戻り先を決める。
7. `wf-review` へ渡せる証跡を出力する。

## 検証結果の分類

検証結果は次に分類する。

- `pass`: 必須検証が通過し、未実行検証のリスクがない、または理由が許容できる。
- `fail`: 検証が失敗し、実装差分またはテスト期待値の修正が必要。
- `blocked`: コマンド不明、権限不足、環境不足、scope不足、人間承認待ちにより検証できない。
- `partial`: 一部検証は通過したが、未実行検証や未確認artifactが残っている。

`pass` は「mergeしてよい」ではない。`wf-review` へ進めるための検証証跡が揃った状態を意味する。

## 失敗分類

失敗または未実行がある場合は、次のいずれかに分類する。

- 実装差分に起因する失敗
- テスト期待値、fixture、snapshot方針の不整合
- 検証コマンドや計画の不足
- 環境、依存関係、sandbox、権限不足
- 外部service、secret、network、dev server前提の不足
- flaky疑い
- 人間承認が必要な操作

分類できない場合は、追加調査が必要として扱う。

検証ログが短く、expected / actual やstack traceが十分に出ない場合は、ログだけで断定せず、承認済み計画、差分、変更ファイル、関連テストの期待値を補助根拠として分類する。その場合は `key log` に観測できた範囲を短く残し、`notes` に補助根拠を明記する。ログが薄いことだけを理由に `不明瞭点` や完了報告の迷った点を増やさない。

## 戻り先

検証結果に応じて戻り先を明記する。

- `pass`: `wf-review`
- 実装差分に起因する失敗: `wf-implement`
- テスト方針、検証範囲、原因、再現条件、影響範囲の不足: `wf-explore`
- 検証専用agentやrepo内検証手順が未整備: `$scaffold-agent-test-runner`
- 権限、secret、外部service、破壊的操作、risk acceptance: human decision

## 出力形式

実PJではrepo内 `test_runner` の応答が詳細証跡である。このskillの最終出力で、コマンドごとの詳細結果や入力証跡を再テンプレート化しない。

単独で会話上に返す場合は、要点だけを短く返す。

```text
verification_status: pass | fail | blocked | partial
executor: test_runner | not_available
executor_session_id: <test_runner session id or unknown>
previous_session_id: <existing id or none>
session_reused: true | false | unknown
new_session_reason: <allowed reason or none>
commands: <passed / failed / not_run counts or one-line summary>
artifact: <path or none>
blocking: <none or one-line summary>
next: wf-review | wf-implement | wf-explore | scaffold-agent-test-runner | human
```

失敗や未実行がある場合だけ、代表的な失敗分類、重要ログの短い要約、戻り先を添える。詳細ログや全コマンド結果は `test_runner` の応答やartifactを参照させる。

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

出力形式そのものを完了報告とする。`test_runner` の詳細結果、全コマンド一覧、入力証跡一覧を同じ返答で繰り返さない。
