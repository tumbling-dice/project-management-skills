---
name: wf-implement
description: "`$wf-implement` が明示された場合だけ使う。人間承認済み計画の範囲で実装、対応テスト、検証、`audit-docs`、`wf-review`、計画内指摘の再修正を完了まで進める。未承認計画、scope拡張、risk acceptanceには使わない。"
---

# wf-implement

このskillは、人間が承認した実装計画に沿ってコード変更と対応テストを行い、検証後に `audit-docs` で作業コンテクスト、state file、実装差分から長期保存すべき内容を `docs/spec/` または `docs/contract/` へバックポートし、文書差分を含めた最終diffを `wf-review` へ渡すためのワークフローである。承認済み計画を実装時のauthorityとして扱い、実装中やレビュー中に見つかった新しい判断は勝手に取り込まず、必要なら計画や調査へ戻す。

## 使わない場面

- 計画が未承認の場合。先に人間レビューと承認を得る。
- 調査結果、影響範囲、実装計画が不足している場合。先に `wf-explore` へ戻す。
- 実装者から独立したreviewだけを単独で行う段階。その場合は `wf-review` を直接使う。
- 検証専用の `test_runner` custom agentやrepo内検証手順を作る段階。その場合は `scaffold-agent-test-runner` を使う。
- repo固有の専門reviewerを作る段階。その場合は `scaffold-agent-reviewer` を使う。

## Authority

実装時のauthorityは、次のいずれかで明示された承認済み計画だけである。

- 人間が承認した `docs/work/<task-id>.md` などの実装計画
- チケット本文やコメントに残された承認済み変更範囲
- ユーザーが会話内で明示した承認済み計画、非対象範囲、検証条件

承認済み計画には、最低限次が必要である。

- 目的と期待動作
- 非対象範囲
- 変更予定ファイルまたは変更対象領域
- テスト方針
- 計画時に根拠にしたドキュメントと、文書不整合の扱い
- 検証コマンドまたは検証手順
- 未確認事項とその扱い
- 人間が修正開始を承認した事実
- UI変更の場合は、対象画面 / route、対象screen spec path、実装時に再確認するUI文書

不足がある場合は `execution_status: blocked` とし、追加調査、計画修正、人間判断のどれが必要かを返す。

state fileは対象ファイル、関連ファイル、検証コマンド、進捗を読むための補助入力であり、scope、判断理由、人間承認のauthorityではない。`$scaffold-project` で作られる `docs/work/_template.state.json` と `references/work/work-context.md` の運用に従い、schemaをこのskillへ複製しない。Markdownとstate fileが矛盾する場合は実装を始めず `execution_status: blocked` とする。

## 手順

1. 承認済み計画を確認する。
   - 目的、期待動作、非対象範囲、変更予定ファイル、テスト方針をMarkdownから抜き出す。
   - `docs/work/<task-id>.state.json` がある場合は、対象ファイル、関連ファイル、検証コマンド、進捗を抜き出す。
   - UI変更の場合は、作業コンテクストに記録された対象画面 / route、対象screen spec path、再確認するUI文書を抜き出す。実装時に対象画面を探索し直さない。
   - 人間承認が確認できない場合は実装を始めない。
2. 作業前の状態を確認する。
   - `git status` などで既存差分を把握する。
   - 既存差分がある場合は、自分の変更と混ぜて扱わない。
   - 計画対象外の差分には触れない。
3. 実装する。
   - 既存実装パターン、既存helper、repoの設計境界に合わせる。
   - 計画範囲内のファイルだけを変更する。
   - UI変更では、承認済み計画に記録された対象screen specだけを参照する。追加の影響画面が見つかった場合は、勝手にscopeへ加えず停止して戻り先を示す。
   - 実装中に計画外の問題を見つけた場合は、勝手にscopeを広げず停止して戻り先を示す。
4. 対応テストを追加または更新する。
   - 実装内容に対応する単体テスト、結合テスト、E2E、fixture、snapshotなどを計画に従って扱う。
   - テスト削除、skip、assertion緩和、理由のないsnapshot大量更新で通さない。
5. 実装者自己確認を行う。
   - 差分が承認済み計画に対応しているか。
   - 非対象範囲へ踏み込んでいないか。
   - 実装中に、計画時のドキュメント根拠と矛盾する新事実を見つけていないか。
   - 認証、認可、tenant、PII、secret、ログ、外部入力への影響を見たか。
   - 不要な依存追加、大きすぎるrefactor、広すぎる例外処理が混ざっていないか。
6. repo手順でMain Agent担当とされたformatterまたはformat checkだけを実行する。その他の検証は先回り実行しない。
7. `wf-verify` を使い、repo内 `test_runner` へ検証を委譲する。`test_runner` やverification手順が未整備の場合は `$scaffold-agent-test-runner` へ戻す。
8. repo-local supplementで後段の専門review、E2E、visual確認が定義されている場合は、その順序に従う。reviewerやroutingが未整備の場合は `$scaffold-agent-reviewer` へ戻す。
9. `audit-docs` を呼び、実装差分、検証証跡、専門review結果、作業コンテクスト、state fileから長期保存すべき文書更新を整理する。auto-fixableな文書修正だけ同じ作業内で適用し、判断が必要なものは戻り先を記録する。
10. 文書差分を含む最終diffを `wf-review` へ渡す。repo-local reviewable gate実装が未整備の場合は `$scaffold-agent-reviewer` へ戻す。
11. `wf-review` の結果を処理する。計画範囲内で修正できるblocking issueだけを修正し、検証、専門review、`audit-docs`、`wf-review` を再実行する。計画外、risk acceptance、scope拡張、権限やsecretが必要な指摘は人間判断または `wf-explore` へ戻す。
12. 同じ指摘で反復している場合、または2回以上修正しても同種のblocking issueが残る場合は、推測で修正を続けず `execution_status: blocked` として、追加調査、人間判断、計画修正のいずれが必要かを示す。

## State File

承認済み計画が `docs/work/<task-id>.md` の場合、同じ `task-id` の `docs/work/<task-id>.state.json` を確認する。state fileの標準形は `$scaffold-project` が作る `docs/work/_template.state.json` と `references/work/work-context.md` に従う。

state fileには、実装中に変わるworkflow status、進捗、対象ファイル、関連ファイル、`commands` のstatus/resultを反映する。実装方針、判断理由、調査メモ、承認事実、secrets、顧客データ、本番ログはstate fileへ書かない。Markdownとstate fileが矛盾した場合は、Markdownの承認済み計画を勝手に上書きせず、`execution_status: blocked` として戻り先を示す。

## 後段workflowの扱い

このskillは実装者の自己確認と、後段workflowへ渡す証跡の統合を担当する。検証実行は `wf-verify`、文書auditは `audit-docs`、reviewable gate判定は `wf-review`、repo固有reviewerやtest_runnerの整備は scaffold 系skillの責務である。

- formatterとformat checkは、repo手順でMain Agent担当とされている場合だけ例外としてMain Agentが実行する。
- `wf-verify`、専門review、E2E、visual確認、`wf-review` の入力と順序はrepo-local supplementに従う。
- reviewerのagent session lifecycleは、`wf-review` の規則に従う。
- 後段workflowの結果が `blocked` の場合は、実装差分で解消できるもの、再計画が必要なもの、人間判断が必要なものに分ける。
- 検証結果やreview結果が `pass` でも、merge、release、本番操作、リスク受容を承認しない。

## Test Runner Session Lifecycle

同一 `wf-implement` 実行中に複数回 `wf-verify` を呼ぶ場合、Main Agent は最初の `wf-verify` が返した `executor_session_id` を現在の `test_runner_session_id` として保持する。以後の `wf-verify` には `existing_test_runner_session_id` として渡し、同じsessionへ追加packetを送る。

再検証では、前回の検証結果、今回のdiffまたは修正要約、再実行するコマンド、前回から変わった前提だけを追加で渡す。長い実装会話や未採用案を再送しない。

新しい `test_runner` sessionを作れるのは、古いdiff、古いcheckout、壊れた環境状態、誤った前提、別task、別ブランチ、別worktreeのいずれかに該当する場合だけである。新しいsessionを作る場合は、検証証跡またはstate file notesに `test_runner_session_id`、`reused: false`、`previous_session_id`、`new_session_reason` を残す。通常の再利用時は `test_runner_session_id` と `reused: true` を残す。

`wf-verify` の結果に session id がない、または新しいsessionの理由がない場合は、検証結果だけで `execution_status: completed` にしない。`wf-verify` へ証跡補完を戻すか、補完できない理由を `partial` / `blocked` に含める。

## subagentを使う場合

実装を分割してsubagentへ委譲する場合は、`subagent-orchestration` に従う。

- Main Agentがtask全体のownerであり続ける。
- subagentごとにwrite scopeを明示する。
- 同じfile、dir、責務を複数subagentへ同時委譲しない。
- subagentには承認済み計画のうち、担当scopeに必要なauthorityだけを渡す。
- subagentの結果が古くなった場合は、統合判断に使わない。
- review用subagentやrepo固有reviewerを呼ぶ場合は、修正作業のsubagentと同じ文脈を渡さず、diffや検証結果などの証跡を渡す。

## Documentation Audit

`audit-docs` は、`wf-review` 前に作業コンテクスト、state file、実装差分から長期保存すべき内容を抽出し、仕様根拠または作業契約へバックポートする文書整合gateである。実装差分の正否を判定するものではない。

- `audit_status: pass`: バックポート不要、またはauto-fixableなバックポートを適用済み。
- `audit_status: findings`: `needs-workflow` または `human-decision` が残っている。`wf-review` へ渡す場合は、残finding、影響、次の戻り先を証跡に含める。
- `audit_status: blocked`: `project_doc_auditor` が使えない、またはauditに必要な証跡が不足している。`execution_status: completed` にはしない。
- `audit-docs` の最終報告は固定reportではなく、修正した文書差分、diffで見るべきポイント、残findingを自然文で返す。`wf-implement` の証跡には、その結果を再テンプレート化せず、reviewに必要な文書差分と残findingだけを残す。
- `docs/work/<task-id>.md` は短命な入力であり、原則として最新化対象にしない。state fileは進捗とcommands結果の更新対象にしてよい。未完了引き継ぎが必要な場合だけMarkdownも更新してよい。

## execution_status

- `completed`: 計画範囲内の実装、対応テスト、自己確認、必要な検証証跡が揃い、`audit-docs` の呼び出しと必要な自動バックポートが完了し、文書差分を含む最終diffで `wf-review` が `pass` した。
- `partial`: 一部実装、一部検証、専門review routing、または `audit-docs` は完了したが、未実行検証、環境不足、専門review待ち、残作業、文書更新workflow待ちがある。
- `blocked`: 計画未承認、scope不足、影響範囲不足、権限不足、環境不足、計画外指摘、人間判断待ちで進められない。

`completed` は「人間レビューへ渡せる材料が揃い、共通gateを通過した」という意味である。merge、release、本番操作、risk acceptanceを許可する意味ではない。

## 出力形式

承認済み計画や調査メモに書かれている内容を最終出力で再掲しない。詳細な検証結果、review結果、audit結果は、それぞれ `test_runner`、reviewable gate、`audit-docs` の応答やartifactを参照させる。

単独で会話上に返す場合は、変更結果、検証状態、未解消blocker、次のownerを残し、経過の再掲と一般的な背景を省く。

```text
execution_status: completed | partial | blocked
plan: <承認済み計画のpathまたは参照>
changed: <files count and short summary>
plan deviations: <none or what was not in the plan>
follow-up decisions: <none or human / wf-explore / other owner>
verification: <pass / fail / blocked / partial, artifact if needed>
review: <pass / needs-specialist-review / blocked, artifact if needed>
docs: <none / changed / findings, diff review points if needed>
next: human review | specialist review | wf-verify | wf-explore | audit-docs | audit-repo-skill | migrate-workflow | human
```

`plan deviations` には、調査メモや承認済み計画に書かれていなかった実装判断、追加で触った範囲、計画外で停止した理由だけを書く。計画通りの作業内容を長く説明しない。

## 禁止事項

- 人間承認が確認できない計画で実装を始めない。
- 承認済み計画の非対象範囲へ踏み込まない。
- 実装中に見つけた別問題を、承認なしに同じ差分へ含めない。
- テスト削除、skip、assertion弱体化、理由のないsnapshot大量更新で検証を通さない。
- 計画時のドキュメント根拠と矛盾する新事実を、計画へ戻さず実装に混ぜない。
- 認証、認可、tenant、PII、secret、ログへの影響を未確認のまま安全扱いしない。
- 実行していない検証を実行済みとして扱わない。
- formatterまたはformat check以外の検証コマンドをMain Agentが先回り実行しない。
- `wf-review` を呼ばずに `execution_status: completed` としない。
- `wf-review` 前の `audit-docs` 呼び出しを省略して `execution_status: completed` としない。
- review指摘が計画外の場合に、承認なしで修正範囲を広げない。
- `audit-docs` のfindingを、実装差分のreview判定や検証結果として扱わない。
- 同じblocking issueで反復しているのに、追加調査や人間判断へ戻さず修正を続けない。
- merge、release、本番操作、risk acceptanceを承認しない。
- ファイルへ実装証跡を作成または更新する場合、shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。`apply_patch` を使う。

## 完了報告

出力形式そのものを完了報告とする。承認済み計画、変更ファイルの全列挙、検証コマンド全文、review/auditの詳細結果を同じ返答で繰り返さない。
