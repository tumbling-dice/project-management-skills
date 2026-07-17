---
name: wf-review
description: "`$wf-review` が明示された場合だけ使う。repo-local reviewable gateへ委譲または照合し、計画、diff、テスト、検証、文書、安全影響の証跡から人間／専門reviewへ進めるか判定する。Main Agentによる代替判定や実装修正には使わない。"
---

# wf-review

このskillは、差分が人間レビューまたは専門reviewへ進める状態かを確認するための共通ワークフローである。実装者の意図ではなく、計画、差分、テスト、検証結果、未実行検証、非対象範囲などの証跡を見る。

このskillは、`$scaffold-agent-reviewer` で整備された repo-local reviewable gate実装、専門reviewer、review routingを使う。加えて、実装済みtest artifactが変わる場合は、共通の `test_reviewer` custom agentへ `$review-tests` を委譲する。reviewer設計、routing文書、gate summary方式の詳細はこのskillへ複製しない。

## 目的

`wf-review` は、コード品質の専門reviewをすべて代替するものではない。役割は、レビュー可能条件を満たしているか、どの専門reviewerへ渡すべきか、どこへ戻すべきかを判定することである。

## 実行形態

実PJでは、Main Agentがこのskillを根拠なしに直接判定してはいけない。必須の共通／repo-local専門reviewを完了してから、repo-local supplementで定義されたreviewable gate agent、またはgate summary方式へ証跡を渡す。

repo-local supplementにreviewable gate実装がない場合は、`status: blocked` とし、`$scaffold-agent-reviewer` へ戻す。実装者の長い会話履歴や採用案を正当化する説明ではなく、承認済み計画、diff、検証証跡、専門review結果などの証跡を入力にする。

## Agent Session Lifecycle

reviewable gateの最終判定は、原則としてreview iterationごとに新しいreviewer sessionを使う。前回の実装説明や指摘対応の流れに引きずられず、現在の計画、diff、検証証跡、専門review結果だけで判定するためである。

- 前回指摘の解消確認だけを同じ観点で行う場合は、前回reviewer sessionを再利用してよい。
- specialist reviewerは、同一taskかつ同一専門領域であれば同じsessionを再利用してよい。再利用時は、前回finding、今回の修正要約、再確認してほしい観点を渡す。
- reviewerへは実装者の長い会話履歴を渡さず、承認済み計画、diff、検証証跡、専門review結果、前回review結果、修正要約などの証跡に絞る。
- reviewerが古いdiff、古い計画、古い検証結果に依存している疑いがある場合は、新しいsessionへ委譲する。
- session再利用の有無は `入力証跡` または `Specialist review routing` に残す。

## 入力証跡

最低限、次を確認する。

- 承認済み実装計画、または人間が承認した変更範囲
- 承認済み計画と同じ `task-id` の `docs/work/<task-id>.state.json` があれば、その対象ファイル、関連ファイル、commands結果
- git diff
- 変更ファイル一覧
- 非対象範囲
- 追加または更新したテスト
- test artifactが変わる場合は `test_reviewer` の `$review-tests` 結果
- 計画時のドキュメント根拠と、文書不整合の扱い
- 実行した検証コマンドと結果
- 未実行検証の理由とリスク
- 実行した専門reviewer、結果、残ったblocking issue
- repo-local supplementで定義されたgate条件、またはreviewable gate agentの入力契約
- 権限、tenant、PII、secret、ログ、外部入力への影響メモ
- 必要に応じたスクリーンショット、ログ要約、E2E結果

入力がない場合は、まず不足証跡を列挙する。差分や検証結果がない状態で `pass` にしない。

ユーザーが明示した検証証跡、計画、スクリーンショット、ログ要約は、git管理外やuntrackedであっても入力証跡として読んでかまわない。その場合は `入力証跡` に「明示指定された外部/未追跡証跡」として記録する。ただし、git diffに含まれない証跡は変更ファイル一覧とは分けて扱い、差分そのものの根拠として混ぜない。

state fileは進捗、対象ファイル、関連ファイル、commands結果を確認する補助証跡であり、承認済み計画や人間承認のauthorityではない。Markdownの承認済み計画や検証証跡とstate fileが矛盾する場合は、`blocked` として戻り先を示す。

## Test implementation review

テスト、fixture、test helper、snapshot、golden fileの追加／更新／削除、またはskip、xfail、retry、timeout、filter、test discovery、assertion設定の変更がある場合は、repo-local gateの最終判定前に `test_reviewer` custom agentへ `$review-tests` を委譲する。

- `$subagent-orchestration` のDelegation Packetで、承認済み範囲、期待動作の根拠、current diff、変更test artifact、対象実装、関連helper／fixture／設定、検証証跡、非対象範囲を渡す。
- `test_reviewer` には実装者の長い会話履歴を渡さず、現在のartifactと証跡だけを渡す。
- `review_status: blocked` はgateのblocking evidenceへ含め、findingごとの戻り先に従う。
- `result: blocked` はreview証跡不足として扱い、不足物を補うまでgateを `pass` にしない。
- test artifactに変更がない場合は、`$review-tests` を未実行理由付きの任意reviewとして増やさない。

このreviewerは実装済みテストだけを対象とする。`wf-explore` のテスト計画に対するpre-implementation reviewでは呼ばない。

## 出力先

ユーザーが「reviewable gateを確認する」「review判定を残す」「人間レビューへ進めるか見る」と依頼している場合は、review判定成果物のファイル作成または更新を優先する。ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力する。

出力先はPJの慣習に従う。慣習がなければ、共有するreview判定として `docs/work/<task-id>-reviewable-gate.md` を推奨する。入力が `docs/work/<task-id>-implementation-plan.md` や `docs/work/<task-id>-verification.md` の場合は、同じ `task-id` を使う。

この命名と出力先選択は既定動作である。出力名が指定されていないことだけを理由に `blocked`、`不明瞭点`、完了報告の迷った点を増やさない。

## 判定

判定は次の3つに分ける。

- `pass`: 人間レビューへ進める。必要な証跡が揃い、blocking issueがない。
- `needs-specialist-review`: 共通gateは大きく満たすが、repo固有の専門reviewが必要。
- `blocked`: レビュー可能条件を満たさない。修正、追加検証、再計画、再調査、人間判断が必要。

`pass` は「merge / releaseしてよい」ではない。レビューへ進める状態を意味する。

`needs-specialist-review` では、共通gate上の実装修正、追加検証、再計画、再調査を要する問題がなければ `Blocking issues` は `なし` とする。専門review未完了であることは `Specialist review routing` と `Non-blocking issues` に分けて書き、`blocked` と混同しない。

## Gate観点

repo-local gate実装が確認する観点は、`$scaffold-agent-reviewer` で整備されたreview routingとgate条件に従う。共通workflowとしては、少なくとも次の証跡が揃っているかを確認する。

- 承認済み計画との対応、非対象範囲、変更ファイル
- テスト追加または更新、テスト弱体化の有無と、trigger時の `$review-tests` 結果
- 計画時のドキュメント根拠と、差分との矛盾有無
- 検証結果、未実行検証の理由とリスク
- 必須専門reviewerの結果または未実行理由
- 権限、privacy、secret、ログ、外部入力などのrisk notes

## 共通skillが判断しないこと

このskillは、repo固有の深い設計判断を単独では行わない。個別の技術名やproduct名を共通skillへ列挙しない。

次のような判断が必要な場合は、repo内skill、custom agent、または人間reviewへroutingする。

- 特定の実装領域に閉じた設計妥当性
- 特定のUI / data / API / persistence / deploy / test architectureの専門判断
- security、privacy、release、complianceなど、人間のリスク受容が必要な判断
- 画面証跡、ログ、E2E、運用手順の専門的な解釈

## Specialist review routing

共通 `test_reviewer` のtriggerは「Test implementation review」に従う。それ以外の専門reviewerの選定はrepo-local review routingに従う。routingが未整備、または必要なreviewerが存在しない場合は、必要な責務と入力証跡を記録し、`$scaffold-agent-reviewer` へ戻す。

triggerに該当するのに共通 `test_reviewer` または `$review-tests` が利用できない場合は、`status: blocked` とし、不足するagent／skillを明記する。Main Agentが同じ会話内でテスト実装reviewを代替しない。

## NG時の戻り先

NG理由に応じて戻り先を明記する。検証証跡不足は `wf-verify`、計画範囲内の実装修正は `wf-implement`、計画・文書根拠・影響範囲の不足は `wf-explore`、reviewer未整備は `$scaffold-agent-reviewer`、risk acceptanceやscope拡張は human decision へ戻す。戻り先が複数ある場合は、blocking issueごとに分けて書く。

## Decision Clarificationへの接続

`blocked` または `needs-specialist-review` の理由に、人間判断、risk acceptance、非対象範囲変更、専門review routingの判断が含まれる場合は、`$idiot` へ渡せるように整理する。

- レビュー可能条件を止めている判断だけを質問化する。
- 修正で解ける問題、検証で解ける問題、再計画が必要な問題、人間判断が必要な問題を分ける。
- security、privacy、release、complianceなどのrisk acceptanceはAIが確定せず、人間判断として残す。
- 専門reviewが必要な場合は、責務、trigger、必要な入力証跡を質問またはroutingとして示す。

このskillの判定自体は `pass` / `needs-specialist-review` / `blocked` のままである。質問化は、次に人間が何を決めれば再reviewへ戻れるかを明確にするための補助出力として扱う。

## 出力形式

実PJではrepo-local reviewable gate実装や専門reviewerの応答が詳細証跡である。このskillの最終出力で、gate項目や入力証跡を再テンプレート化しない。

単独で会話上に返す場合は、判定、blocking evidence、未実行review、戻り先を残し、通過項目と入力一覧の再掲を省く。

```text
status: pass | needs-specialist-review | blocked
review source: <repo-local gate agent / gate summary / specialist reviewer>
blocking: <none or one-line summary>
specialist review: <required / not required / completed>
missing evidence: <none or one-line summary>
next: human review | specialist review | wf-verify | wf-implement | wf-explore | idiot | human
```

必要な場合だけ、見るべきartifactやreviewer応答のpathを添える。blocking issueが複数ある場合は、戻り先ごとに短くまとめる。

## 禁止事項

- 実装者の説明だけでpassにしない。
- repo-local supplementのgate条件や必須reviewerを読まずにpassにしない。
- triggerに該当する `$review-tests` を省略またはMain Agentで代替してpassにしない。
- 検証未実行や証跡不足を「問題なし」と扱わない。
- テスト削除、skip、assertion弱体化を見逃してpassにしない。
- ドキュメント根拠不足、または計画時の文書根拠と差分の矛盾を見逃してpassにしない。
- 非対象範囲への変更を人間承認なしにpassにしない。
- 専門reviewが必要な差分を、この共通skillだけで安全と断定しない。
- release、merge、本番操作、リスク受容を承認しない。

## 完了報告

出力形式そのものを完了報告とする。呼び出し先agentの詳細結果、gate項目、入力証跡一覧を同じ返答で繰り返さない。
