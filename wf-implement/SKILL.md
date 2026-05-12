---
name: wf-implement
description: ユーザーが $wf-implement を明示した場合だけ使う。人間が承認した実装計画をauthorityとして、計画範囲内の修正、対応テスト追加・更新、自己確認、関連検証、wf-review 前の audit-docs 呼び出し、wf-review 呼び出し、指摘対応の再修正・再テスト・再レビュー反復を行う。
---

# wf-implement

このskillは、人間が承認した実装計画に沿ってコード変更と対応テストを行い、検証後に `audit-docs` で文書の同期漏れを点検し、文書差分を含めた最終diffを `wf-review` へ渡し、指摘があれば修正、テスト、再レビューを繰り返すためのワークフローである。承認済み計画を実装時のauthorityとして扱い、実装中やレビュー中に見つかった新しい判断は勝手に取り込まず、必要なら計画や調査へ戻す。

## 使う場面

- `wf-explore` で作成した計画が人間に承認され、修正開始が許可された。
- 承認済み計画の範囲内で、実装修正と対応テスト追加・更新を進めたい。
- 実装者として、差分、テスト、検証結果、未実行理由、残懸念を整理したい。
- 実装後に `wf-review` を呼び、blocking issue があれば修正と再検証を繰り返したい。
- `wf-review` へ渡す前に、計画時の文書根拠、設計書、検証手順、review条件が差分と食い違ったまま残っていないか `audit-docs` で点検したい。

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

不足がある場合は `execution_status: blocked` とし、追加調査、計画修正、人間判断のどれが必要かを返す。

## 手順

1. 承認済み計画を確認する。
   - 目的、期待動作、非対象範囲、変更予定ファイル、テスト方針、検証コマンドを抜き出す。
   - 人間承認が確認できない場合は実装を始めない。
2. 作業前の状態を確認する。
   - `git status` などで既存差分を把握する。
   - 既存差分がある場合は、自分の変更と混ぜて扱わない。
   - 計画対象外の差分には触れない。
3. 実装する。
   - 既存実装パターン、既存helper、repoの設計境界に合わせる。
   - 計画範囲内のファイルだけを変更する。
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
6. formatterまたはformat checkを実行する。
   - repo手順で実装者担当とされるformatterやformat checkはMain Agentが実行する。
   - formatterが失敗した場合は、計画範囲内のformat差分として直し、test、lint、review、E2Eへ進む前に再確認する。
   - format以外のtest、lint、build、typecheck、E2E、visual確認を先回り実行しない。
7. 関連検証を委譲する。
   - 承認済み計画にある検証コマンドを優先する。
   - formatterまたはformat checkを除く検証コマンドは、`wf-verify` を使ってrepo内 `test_runner` custom agentへ委譲する。
   - repo内 `test_runner` が使えない場合は、直接実行せず `execution_status: blocked` として `$scaffold-agent-test-runner` へ戻す。
   - 承認済み計画のコマンドが環境理由で実行できない場合、repo内 `test_runner` はrepo手順や実行環境で明らかな同等コマンドを補助検証として実行してもよい。ただし、元の計画コマンドの失敗または未実行を隠さず記録し、同等扱いが承認されていない限り `pass` や `completed` の根拠にしない。
8. 失敗時の扱いを決める。
   - 実装差分に起因する失敗は、計画範囲内で修正して再検証する。
   - 計画、テスト方針、検証範囲、原因、影響範囲の不足なら `wf-explore` へ戻す。
   - 権限、secret、外部service、破壊的操作、risk acceptanceが必要なら人間判断へ戻す。
9. repo固有の専門reviewを呼び出す。
   - repo-local supplementやreview routingが、特定の専門reviewerを非E2E検証後に呼ぶよう指定している場合は、その順序に従う。
   - 専門reviewerがblocking issueを返した場合は、計画範囲内で修正し、format、関連検証、同じ専門reviewを再実行する。
   - 専門reviewerのblocking issueが残っている間は、E2E、screenshot更新、visual確認へ進みない。
10. E2E、screenshot、visual確認を委譲する。
   - repo-local supplementがE2Eやvisual確認を後段に分けている場合は、専門reviewのblocking issueを解消した後に `test_runner` やrepo固有reviewerへ委譲する。
   - screenshot、golden、visual baselineの更新は、repo手順と人間承認に従い、暗黙に通過条件へ混ぜない。
11. `audit-docs` を呼び出す。
   - `wf-review` へ進む前に、実装証跡、検証証跡、専門review結果、承認済み計画、計画時のドキュメント根拠、変更後の代表的な実装/テストファイルを `project_doc_auditor` へ渡す。
   - audit目的は、実装差分により README、AGENTS、PJ文書、設計書、検証手順、review条件、代表的な作業メモが古い前提のまま残っていないか確認することに限定する。
   - 実PJではMain Agentが `audit-docs` を直接実行しない。`project_doc_auditor` が使えない場合は、`execution_status: blocked` として必要なagentが無いことを報告する。
   - auditは実装、検証実行、review判定を代替しない。文書差分を含めた最終diffを `wf-review` で確認できるようにするための前段である。
12. audit結果を処理する。
   - `auto-fixable`: `audit-docs` の条件に合う文書修正だけを同じ作業内で適用し、Applied Fixes と変更ファイルを実装証跡へ追記する。適用後の文書差分も `wf-review` 入力に含める。
   - `needs-workflow`: 実装差分へ混ぜず、推奨戻り先を `wf-explore`、`migrate-workflow`、`audit-repo-skill` などへ分ける。
   - `human-decision`: 仕様、scope、risk acceptance、security、privacy、release、本番操作に関わる判断として、人間判断または `idiot` へ戻す。
   - `blocked`: `audit-docs` の委譲先不足、文書根拠不足、証跡不足を記録し、`execution_status: partial` または `blocked` として次の戻り先を示す。
13. `wf-review` を呼び出す。
   - repo-local supplementにreviewable gate agentが定義されている場合は、そのagentへ委譲する。
   - repo-local supplementが、専門reviewer結果とreviewable gate文書の照合でgate summaryを作る方式を定義している場合は、その方式を使う。
   - 承認済み計画、git diff、変更ファイル、テスト差分、計画時のドキュメント根拠、検証結果、未実行検証、非対象範囲、自己確認メモ、`audit-docs` 結果、適用済み文書修正、残findingを渡す。
   - 実装者の長い会話履歴、未検証の仮説、採用案を正当化する説明をreview authorityとして渡さない。
   - repo-local supplementにgate実装がない場合は、同一Main Agentで代替判定せず `execution_status: blocked` として `$scaffold-agent-reviewer` へ戻す。
14. review結果を処理する。
   - `pass`: 実装、文書audit、reviewのサイクルを完了し、人間レビューへ渡す。
   - `blocked`: 指摘が承認済み計画の範囲内で修正可能なら、修正、テスト、検証、`audit-docs`、再レビューを行う。
   - `needs-specialist-review`: repo内の専門reviewerへroutingする。必要なreviewerが未整備なら `scaffold-agent-reviewer` を提案する。
   - 計画外の変更、リスク受容、権限、secret、外部service、破壊的操作が必要なら人間判断へ戻す。
15. 終了条件に達するまで、修正、テスト、検証、専門review、`audit-docs`、`wf-review` を繰り返す。

## 検証の扱い

このskillは実装者の自己検証と、`wf-review` の呼び出しまでを担当する。review可能判定そのものは `wf-review` の出力を根拠として扱う。

- 検証は `wf-verify` をrepo内 `test_runner` custom agentへ委譲して行う。
- formatterとformat checkは、repo手順でMain Agent担当とされている場合だけ例外としてMain Agentが実行する。formatが終わるまでtest、lint、review、E2Eへ進みない。
- Main Agentは、formatterまたはformat check以外の検証コマンドを先回り実行しない。
- 検証失敗を修正する場合でも、承認済み計画の範囲内に限る。
- 検証結果が `pass` でも、merge、release、本番操作、リスク受容を承認しない。
- 計画された検証コマンドと実際に成功した補助コマンドが異なる場合は、両方を分けて記録する。補助コマンドの成功は有用な証跡であるが、計画コマンドの代替として承認されていないなら `wf-review` へ未解決リスクとして渡す。

## Review Cycle

`wf-review` は、実装サイクル内の独立したgateとして呼び出す。Main Agentは呼び出し、結果の解釈、修正範囲の判断、再実行のownerである。実PJではrepo-local supplementで定義されたreviewable gate実装を使う。gate実装は、repo内にscaffoldされたreviewable gate用custom agent、または専門reviewer結果とgate文書の照合で作るgate summaryのどちらでもかまわない。同じMain Agentが証跡なしに代替判定しない。

review入力には最低限次を渡す。

- 承認済み計画、または人間が承認した変更範囲
- git diff
- 変更ファイル一覧
- 追加または更新したテスト
- 実行した検証コマンドと結果
- 未実行検証の理由とリスク
- 実行した専門reviewer、結果、残ったblocking issue
- 非対象範囲
- 権限、tenant、PII、secret、ログ、外部入力への影響メモ

review結果ごとの扱いは次の通りである。

- `pass`: `audit-docs` 実行後の文書差分を含む最終diffがreviewを通過した状態として、`execution_status: completed` とし、人間レビューへ渡せる証跡をまとめる。
- `blocked`: blocking issueを分類する。計画範囲内で修正できるものは修正、対応テスト、検証、再reviewを行う。計画外なら停止して戻り先を示す。
- `needs-specialist-review`: 実装修正で解消できる指摘ではないため、専門reviewへroutingする。repo内reviewerがなければ `scaffold-agent-reviewer` へ戻す。

同じ指摘で反復している場合、または2回以上修正しても同種のblocking issueが残る場合は、推測で修正を続けず `execution_status: blocked` として、追加調査、人間判断、計画修正のいずれが必要かを示す。

## subagentを使う場合

実装を分割してsubagentへ委譲する場合は、`subagent-orchestration` に従う。

- Main Agentがtask全体のownerであり続ける。
- subagentごとにwrite scopeを明示する。
- 同じfile、dir、責務を複数subagentへ同時委譲しない。
- subagentには承認済み計画のうち、担当scopeに必要なauthorityだけを渡す。
- subagentの結果が古くなった場合は、統合判断に使わない。
- review用subagentやrepo固有reviewerを呼ぶ場合は、修正作業のsubagentと同じ文脈を渡さず、diffや検証結果などの証跡を渡す。

## Documentation Audit

`audit-docs` は、`wf-review` 前に設計書や検証手順が古いまま残ることを防ぐ文書整合gateである。実装差分の正否を判定するものではない。

- `audit_status: pass`: 文書更新不要、またはauto-fixableな文書修正を適用済み。
- `audit_status: findings`: `needs-workflow` または `human-decision` が残っている。`wf-review` へ渡す場合は、残finding、影響、次の戻り先を証跡に含める。
- `audit_status: blocked`: `project_doc_auditor` が使えない、またはauditに必要な証跡が不足している。`execution_status: completed` にはしない。

## execution_status

- `completed`: 計画範囲内の実装、対応テスト、自己確認、必要な検証証跡が揃い、`audit-docs` の呼び出しと必要な自動文書修正が完了し、文書差分を含む最終diffで `wf-review` が `pass` した。
- `partial`: 一部実装、一部検証、専門review routing、または `audit-docs` は完了したが、未実行検証、環境不足、専門review待ち、残作業、文書更新workflow待ちがある。
- `blocked`: 計画未承認、scope不足、影響範囲不足、権限不足、環境不足、計画外指摘、人間判断待ちで進められない。

`completed` は「人間レビューへ渡せる材料が揃い、共通gateを通過した」という意味である。merge、release、本番操作、risk acceptanceを許可する意味ではない。

## 出力形式

```md
# Implementation Execution Evidence

## Status

execution_status: completed / partial / blocked

## Approved Plan

- plan source:
- human approval:
- non-goals:

## Changes

- changed files:
- summary:
- out of scope changes: なし / あり

## Tests

- added or updated:
- not changed and reason:

## Self Check

- plan alignment:
- non-goal boundary:
- documentation evidence consistency:
- auth / permission / tenant:
- PII / secret / logs:
- external input:
- dependency / refactor scope:

## Verification

- command:
  reason:
  result:
  executor: main_agent_formatter / test_runner / not_run
  artifact:
  notes:

## Specialist Review

- reviewer:
  result:
  blocking issues:
  action taken:

## Not Run

- command:
  reason:
  risk:
  next action:

## Reviewable Gate

- iteration:
- executor: repo_reviewable_gate_agent
- result: pass / needs-specialist-review / blocked
- blocking issues:
- non-blocking issues:
- specialist review:
- action taken:

## Documentation Audit

- executor: project_doc_auditor / not_available / not_run
- audit_status: pass / findings / blocked
- scope:
- findings:
- applied fixes:
- next action:

## Remaining Concerns

- なし / あり

## Next Step

- human review / specialist review / wf-verify / wf-explore / audit-docs / audit-repo-skill / migrate-workflow / human decision
```

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

最後に次を報告する。

- `execution_status`
- 承認済み計画の参照元
- 変更内容と変更ファイル
- 追加または更新したテスト
- 実行または委譲した検証コマンドと結果
- `wf-review` の結果と反復回数
- `audit-docs` の結果、適用した自動文書修正、残finding
- 未実行検証、残懸念、次の戻り先
