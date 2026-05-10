---
name: post-review-fix-triage
description: このskillは workflow-router のrouting結果、またはユーザーが $post-review-fix-triage を明示した場合だけ使う。通常依頼から直接発火しない。人間review、specialist review、reviewable-gate-review の指摘を、承認済み計画内で修正するもの、ドキュメント根拠不足として再計画へ戻すもの、再検証するもの、追加調査へ戻すもの、人間判断へ戻すものに分類する。指摘対応の実装は行わない。
---

# Post Review Fix Triage

このskillは、review後の指摘をそのまま実装へ流し込まず、どの指摘をどのworkflowへ戻すべきか分類するためのワークフローです。目的は、review指摘を承認済み計画のscope、検証証跡、非対象範囲、人間判断に照らして整理し、次の修正サイクルへ渡せる形にすることです。

## 使う場面

- 人間review、specialist review、`reviewable-gate-review` の指摘が返ってきた。
- `implementation-execution-workflow` の再修正へ戻す前に、指摘が計画内か計画外かを分けたい。
- 複数のreviewerの指摘が混ざっており、修正、検証、再計画、追加調査、人間判断の戻り先を整理したい。
- blocking / non-blocking / follow-up の扱いを明確にしたい。

## 使わない場面

- 指摘を実装する場合。その場合は `implementation-execution-workflow` へ戻します。
- 新しい実装前調査と計画を作る場合。その場合は `implementation-prep-workflow` を使います。
- review判定そのものを行う場合。その場合は `reviewable-gate-review` を使います。
- 人間の代わりにrisk acceptance、security、release、scope拡張を承認する場合。

## 入力

最低限、次を確認します。

- 承認済み実装計画、または人間が承認した変更範囲
- 現在のdiff、変更ファイル、実装証跡
- 検証証跡、未実行検証、artifact
- 計画時のドキュメント根拠と、文書不整合の扱い
- `reviewable-gate-review` の結果
- 人間review comment、specialist review結果
- 非対象範囲
- 権限、tenant、PII、secret、ログ、外部入力、release、risk acceptanceに関する指摘

入力が不足して指摘の扱いを分類できない場合は、`triage_status: blocked` として不足している入力を列挙します。

## 分類

各指摘を次のいずれかに分類します。

- `fix-in-plan`: 承認済み計画の範囲内で修正できる。
- `verify-only`: 実装修正ではなく、検証不足または証跡不足として扱う。
- `re-plan`: 変更範囲、テスト方針、期待動作、非対象範囲の変更が必要。
- `investigate`: 事実確認、原因調査、影響範囲調査が必要。
- `human-decision`: risk acceptance、scope拡張、security、privacy、release、外部service、破壊的操作など、人間判断が必要。
- `specialist-review`: repo固有の専門reviewが必要、または専門review結果待ち。
- `non-blocking`: 人間レビューでは見るが、今回の実装修正を止めない。
- `blocked-input-missing`: 承認済み計画、current diff、検証証跡などが不足しており、指摘を安全に分類できない。

## 手順

1. review指摘を1件ずつ抽出する。
2. 指摘ごとに、根拠となるreview source、対象ファイル、対象挙動、blocking度を確認する。
3. 承認済み計画と非対象範囲に照らして、計画内で修正可能か判断する。
4. 修正で解けるもの、検証で解けるもの、再計画が必要なもの、調査が必要なもの、人間判断が必要なものを分ける。
5. `implementation-execution-workflow` へ戻す指摘は、修正scope、変更可能ファイル、必要テスト、再検証、再review入力をまとめる。
6. 計画外の指摘は、勝手に実装scopeへ入れず、戻り先と人間判断の要否を示す。

入力不足で分類できない場合は、指摘を `fix-in-plan` として扱わず、`blocked-input-missing` にします。不足している計画、diff、検証証跡、review sourceを列挙し、必要なら `workflow-artifact-handoff` へ戻して入力を揃えます。

## 指摘対応の基準

`fix-in-plan` にできる条件:

- 承認済み計画の目的、期待動作、変更対象領域に含まれる。
- 非対象範囲へ踏み込まない。
- 既存テストの削除、skip、assertion弱体化を必要としない。
- auth、permission、tenant、PII、secret、ログ、外部入力への新しいrisk acceptanceを必要としない。
- 要件、設計、検証手順、review条件などの文書根拠と矛盾しない。矛盾する場合は `re-plan` または `investigate` として扱う。

`re-plan` または `human-decision` に戻す条件:

- 変更予定ファイルや非対象範囲を広げる必要がある。
- 期待動作、仕様、テスト方針の変更が必要。
- release、security、privacy、compliance、外部service、破壊的操作、risk acceptanceが関係する。
- reviewer間で矛盾があり、AIだけで優先順位を確定できない。

全体の `triage_status` は次の基準で選びます。

- `ready_for_fix`: 少なくとも1件の `fix-in-plan` があり、その修正scopeを安全に切り出せる。別の指摘が `re-plan`、`human-decision`、`verify-only`、`non-blocking` に分かれていても、Fix Packetに混ぜずBlocked Itemsへ分離できていれば使えます。
- `blocked`: 入力不足、指摘の矛盾、承認不足により、実装へ戻すFix Packetを安全に作れない。
- `ready_for_plan`: 主な戻り先が `implementation-prep-workflow`。
- `ready_for_investigation`: 主な戻り先が `implementation-prep-workflow`。
- `needs_human_decision`: 主な戻り先が人間判断または `decision-clarification-workflow`。

## 出力形式

```md
# Post Review Fix Triage

## Status

triage_status: ready_for_fix / blocked / ready_for_plan / ready_for_investigation / needs_human_decision

## Inputs

- approved plan:
- current diff:
- verification:
- documentation evidence:
- review sources:
- non-goals:

## Findings

- id:
  source:
  summary:
  blocking: yes / no
  classification: fix-in-plan / verify-only / re-plan / investigate / human-decision / specialist-review / non-blocking / blocked-input-missing
  reason:
  affected files:
  allowed fix scope:
  required tests:
  required verification:
  next owner:

## Fix Packet For Implementation

- scope:
- allowed files:
- do not change:
- tests:
- verification:
- review inputs after fix:

## Blocked Items

- item:
  why blocked:
  next workflow:
  human decision:

## Next Step

- implementation-execution-workflow / verification-workflow / implementation-prep-workflow / specialist review / workflow-artifact-handoff / decision-clarification-workflow / human decision
```

## 禁止事項

- review指摘を分類せず、すべて実装scopeへ入れない。
- 承認済み計画の非対象範囲を、review指摘を理由に勝手に広げない。
- 人間の代わりにrisk acceptance、security、privacy、release判断を確定しない。
- テスト削除、skip、assertion弱体化を修正方針として許可しない。
- 実装、テスト更新、検証実行、review判定をこのskill内で行わない。

## 完了報告

最後に次を報告します。

- `triage_status`
- `implementation-execution-workflow` へ戻せる指摘数
- 再計画、追加調査、人間判断、専門reviewへ戻す指摘
- 次workflowへ渡す入力
