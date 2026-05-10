---
name: reviewable-gate-review
description: このskillは workflow-router のrouting結果、またはユーザーが $reviewable-gate-review を明示した場合だけ使う。通常依頼から直接発火しない。実PJでは Main Agent が直接実行せず、repo内にscaffoldされた reviewable gate用custom agentへ委譲する。実装者とは独立した視点で、差分が人間レビューや専門reviewへ進める状態かを判定する。承認済み計画、git diff、変更ファイル、検証結果、未実行検証、非対象範囲、テスト追加・更新、計画時のドキュメント根拠、権限/PII/secret/ログ影響の証跡を確認する。
---

# Reviewable Gate Review

このskillは、差分が人間レビューまたは専門reviewへ進める状態かを確認するための共通ワークフローです。実装者の意図ではなく、計画、差分、テスト、検証結果、未実行検証、非対象範囲などの証跡を見ます。

## 目的

`reviewable-gate-review` は、コード品質の専門reviewをすべて代替するものではありません。役割は、レビュー可能条件を満たしているか、どの専門reviewerへ渡すべきか、どこへ戻すべきかを判定することです。

## 実行形態

実PJでは、Main Agentがこのskillを直接実行してはいけません。必ずrepo内にscaffoldされた reviewable gate用custom agentへ委譲して実行します。

- Main Agentがこのskillを読んだ場合は、自分でreviewable gateを判定せず、承認済み計画、git diff、変更ファイル一覧、追加/更新テスト、検証証跡、未実行検証、非対象範囲、risk notesを短くまとめてrepo内reviewable gate agentへ渡します。
- repo内reviewable gate agentが使えない場合は、`status: blocked` とし、`$specialist-reviewer-scaffold` へ戻します。
- 実PJでは、同一Main Agentによる代替reviewable gateを行いません。代替reviewable gateは、このskill自体の開発・検証で明示された場合だけ行います。
- 実装者の長い会話履歴や採用案を正当化する説明ではなく、証跡を入力にします。
- 入力が不足している場合は推測でpassにせず、`blocked` または `needs-specialist-review` にします。

## 入力証跡

最低限、次を確認します。

- 承認済み実装計画、または人間が承認した変更範囲
- git diff
- 変更ファイル一覧
- 非対象範囲
- 追加または更新したテスト
- 計画時のドキュメント根拠と、文書不整合の扱い
- 実行した検証コマンドと結果
- 未実行検証の理由とリスク
- 権限、tenant、PII、secret、ログ、外部入力への影響メモ
- 必要に応じたスクリーンショット、ログ要約、E2E結果

入力がない場合は、まず不足証跡を列挙します。差分や検証結果がない状態で `pass` にしません。

ユーザーが明示した検証証跡、計画、スクリーンショット、ログ要約は、git管理外やuntrackedであっても入力証跡として読んでかまいません。その場合は `入力証跡` に「明示指定された外部/未追跡証跡」として記録します。ただし、git diffに含まれない証跡は変更ファイル一覧とは分けて扱い、差分そのものの根拠として混ぜません。

## 出力先

ユーザーが「reviewable gateを確認する」「review判定を残す」「人間レビューへ進めるか見る」と依頼している場合は、review判定成果物のファイル作成または更新を優先します。ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力します。

出力先はPJの慣習に従います。慣習がなければ、共有するreview判定として `docs/work/<task-id>-reviewable-gate.md` を推奨します。入力が `docs/work/<task-id>-implementation-plan.md` や `docs/work/<task-id>-verification.md` の場合は、同じ `task-id` を使います。

この命名と出力先選択は既定動作です。出力名が指定されていないことだけを理由に `blocked`、`不明瞭点`、完了報告の迷った点を増やしません。

## 判定

判定は次の3つに分けます。

- `pass`: 人間レビューへ進める。必要な証跡が揃い、blocking issueがない。
- `needs-specialist-review`: 共通gateは大きく満たすが、repo固有の専門reviewが必要。
- `blocked`: レビュー可能条件を満たさない。修正、追加検証、再計画、再調査、人間判断が必要。

`pass` は「merge / releaseしてよい」ではありません。レビューへ進める状態を意味します。

`needs-specialist-review` では、共通gate上の実装修正、追加検証、再計画、再調査を要する問題がなければ `Blocking issues` は `なし` とします。専門review未完了であることは `Specialist review routing` と `Non-blocking issues` に分けて書き、`blocked` と混同しません。

## Gate項目

次を確認します。

- 計画との対応: 差分が承認済み計画や変更範囲に対応している。
- 非対象範囲: 非対象範囲へ踏み込んでいない。
- テスト対応: 変更内容に対応するテストがある。ない場合は理由が記録されている。
- テスト弱体化なし: テスト削除、skip、assertion緩和、snapshot大量更新で通していない。
- ドキュメント根拠: 調査または計画で参照した仕様、設計、検証手順、review条件、AI利用ルールなどが根拠として記録されている。差分がその根拠と矛盾していない。
- 検証結果: 関連テスト、build、lint、typecheck、E2E、smoke testなど、計画された検証の結果が記録されている。
- 未実行検証: 未実行の理由とリスクが明記されている。
- 権限 / privacy / secret / ログ: 影響有無が確認されている。未確認なら安全扱いしない。
- 専門review要否: repo固有の専門reviewerへ渡す必要があるか判定している。

## 共通skillが判断しないこと

このskillは、repo固有の深い設計判断を単独では行いません。個別の技術名やproduct名を共通skillへ列挙しません。

次のような判断が必要な場合は、repo内skill、custom agent、または人間reviewへroutingします。

- 特定の実装領域に閉じた設計妥当性
- 特定のUI / data / API / persistence / deploy / test architectureの専門判断
- security、privacy、release、complianceなど、人間のリスク受容が必要な判断
- 画面証跡、ログ、E2E、運用手順の専門的な解釈

## Specialist review routing

repo内に専門review skillやcustom agentがある場合は、それを優先します。なければ、必要なreviewerの責務と入力証跡を提案します。repo固有reviewerの作成には `$specialist-reviewer-scaffold` を使います。

routingは技術名ではなく、責務とリスクで表現します。

- user-visible behavior / UI evidence
- data boundary / permission / privacy
- service behavior / business rule
- persistence / data compatibility
- external input / import / export
- build / deploy / config / observability
- test integrity / E2E / visual evidence

## NG時の戻り先

NG理由に応じて戻り先を明記します。

- 検証未実行: `verification-workflow`
- 実装ミス候補: `implementation-execution-workflow`
- テスト不足、テスト方針不足: `implementation-plan-gate`
- ドキュメント根拠不足または文書不整合: `implementation-plan-gate` または `investigation-workflow`
- テスト削除、skip、assertion弱体化、snapshot大量更新で通している場合: `implementation-execution-workflow`
- 調査不足、影響範囲漏れ: `investigation-workflow`
- 非対象範囲変更、security、privacy、release判断: human decision または specialist review

戻り先が複数ある場合は、blocking issueごとに分けて書きます。

非対象範囲違反でも、差分を戻す、テストを復元する、計画範囲内へ修正し直すことで解消できる場合は、まず `implementation-execution-workflow` へ戻します。人間判断やspecialist reviewへ回すのは、非対象範囲を正式に拡張するか、security、privacy、release、complianceのrisk acceptanceが必要な場合です。

## Decision Clarificationへの接続

`blocked` または `needs-specialist-review` の理由に、人間判断、risk acceptance、非対象範囲変更、専門review routingの判断が含まれる場合は、`$decision-clarification-workflow` へ渡せるように整理します。

- レビュー可能条件を止めている判断だけを質問化します。
- 修正で解ける問題、検証で解ける問題、再計画が必要な問題、人間判断が必要な問題を分けます。
- security、privacy、release、complianceなどのrisk acceptanceはAIが確定せず、人間判断として残します。
- 専門reviewが必要な場合は、責務、trigger、必要な入力証跡を質問またはroutingとして示します。

このskillの判定自体は `pass` / `needs-specialist-review` / `blocked` のままです。質問化は、次に人間が何を決めれば再reviewへ戻れるかを明確にするための補助出力として扱います。

## 出力形式

```md
# Reviewable Gate Review

## 判定

status: pass / needs-specialist-review / blocked

## 入力証跡

- plan:
- diff:
- changed files:
- tests:
- documentation evidence:
- verification:
- non-goals:
- risk notes:

## Gate項目

- 計画との対応:
- 非対象範囲:
- テスト対応:
- テスト弱体化なし:
- ドキュメント根拠:
- 検証結果:
- 未実行検証:
- 権限 / privacy / secret / ログ:
- 専門review要否:

## Specialist review routing

- reviewer:
- trigger:
- inputs:
- reason:

## Blocking issues

- なし / あり

## Non-blocking issues

- なし / あり

## 人間判断が必要な点

- なし / あり

## Decision Clarification

- なし / あり
- next workflow:
- blocking decisions:

## 次の戻り先

- verification-workflow / implementation-execution-workflow / implementation-plan-gate / investigation-workflow / decision-clarification-workflow / specialist review / human decision
```

## 禁止事項

- 実装者の説明だけでpassにしない。
- 検証未実行や証跡不足を「問題なし」と扱わない。
- テスト削除、skip、assertion弱体化を見逃してpassにしない。
- ドキュメント根拠不足、または計画時の文書根拠と差分の矛盾を見逃してpassにしない。
- 非対象範囲への変更を人間承認なしにpassにしない。
- 専門reviewが必要な差分を、この共通skillだけで安全と断定しない。
- release、merge、本番操作、リスク受容を承認しない。

## 完了報告

最後に次を報告します。

- status
- blocking issueの有無
- specialist reviewの要否
- 不足している証跡
- ドキュメント根拠不足や文書不整合の有無
- 次の戻り先
- 人間判断が必要な点と、`decision-clarification-workflow` へ渡す必要の有無
