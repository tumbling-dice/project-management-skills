---
name: workflow-router
description: ユーザー依頼、作業状況、既存成果物、差分、review結果、検証状況から、次に使うべき共通workflow skillを選ぶためのrouting skill。調査、計画、実装、検証、review、triage、handoff、scaffold、auditのどれに進むかを少ない入力で判定し、必要な入力、止まる条件、次のskill名を返す。対象workflowの実行、実装、検証、review判定は行わない。
---

# Workflow Router

このskillは、今どのworkflowへ進むべきかを判定するための軽量routing skillです。目的は、Main Agentが毎回すべてのworkflowを読み比べなくても、次に使うskill、必要な入力、止まる条件を短く決められるようにすることです。

## 実行形態

実PJでは、Main Agentがこのskillを直接実行してはいけません。必ず `workflow_router` custom agentへ委譲して実行します。

- Main Agentがこのskillを読んだ場合は、自分でroutingせず、ユーザー依頼、現在の作業段階、承認済み計画の有無、既存成果物、差分、review結果、検証状況を短くまとめて `workflow_router` へ渡します。
- `workflow_router` custom agentが使えない場合は、`routing_status: blocked` とし、必要なagentが無いことを報告します。
- 実PJでは、同一Main Agentによる代替routingを行いません。代替routingは、このskill自体の開発・検証で明示された場合だけ行います。
- `workflow_router` の返答を受けた後、Main Agentが該当workflow skillを実行します。

## 使う場面

- ユーザー依頼が曖昧で、調査、計画、実装、検証、review、triageのどこから始めるべきか迷う。
- 既存成果物やreview結果があり、次workflowへ進む前に戻り先を決めたい。
- 長い作業の途中で、次に使うskillを最小文脈で選びたい。
- repo内 `test_runner`、専門reviewer、handoff、auditなど、scaffoldや運用系workflowが必要か判断したい。

## 使わない場面

- 選んだworkflowをそのまま実行する場合。routing後に該当skillを使います。
- コード修正、テスト更新、検証実行、review判定を行う場合。
- routing結果をファイルへ出力する場合。結果は会話上に返します。
- 人間の代わりに承認、仕様決定、risk acceptance、release判断を行う場合。
- repo固有の検証コマンドや専門review観点を詳しく設計する場合。

## 入力

分かる範囲で次を確認します。すべて揃っていなくても、routingできる場合は止まりません。

- ユーザー依頼
- 現在の作業段階
- 承認済み計画の有無
- 調査結果、計画、実装証跡、検証証跡、review結果、triage結果の有無
- git diffや変更ファイルの有無
- 調査または計画で使ったドキュメント根拠の有無
- repo内 `test_runner`、reviewable gate agent、専門reviewer、routing文書の有無
- blocked理由、人間判断待ち、未確認事項

入力不足でroutingできない場合は、`routing_status: blocked` とし、不足物を列挙します。

## Routing Table

| 状況 | 次に使うskill |
| --- | --- |
| 新規PJ、文書が薄い既存PJ、AI利用ルールや初期文書を作りたい | `project-startup-scaffold` |
| 実装前に原因、影響範囲、既存パターンを調べたい | `investigation-workflow` |
| 調査結果や一時コンテキストから実装計画を作りたい | `implementation-plan-gate` |
| blocked理由や人間判断待ちを質問へ絞りたい | `decision-clarification-workflow` |
| 人間承認済み計画があり、実装と対応テストへ進みたい | `implementation-execution-workflow` |
| 実装後に検証範囲を確定し、検証証跡を作りたい | `verification-workflow` |
| 差分が人間reviewや専門reviewへ進める状態か見たい | `reviewable-gate-review` |
| review指摘を修正、再検証、再計画、調査、人間判断へ分類したい | `post-review-fix-triage` |
| バグ修正や実装の根拠になる要件、設計、検証手順、AGENTS、review条件を確認したい | `investigation-workflow` / `implementation-plan-gate` |
| PJ文書群の矛盾、古い前提、未決事項、実装や検証手順との食い違いを点検したい | `project-doc-consistency-audit` |
| 長い作業文脈や成果物を次workflowへ渡すpacketにしたい | `workflow-artifact-handoff` |
| repo内に検証専用 `test_runner` と検証手順を作りたい | `test-runner-scaffold` |
| repo内にreviewable gate agent、専門reviewer、review routingを作りたい | `specialist-reviewer-scaffold` |
| repo内skill、agent、AGENTS.md、routing、検証手順を点検したい | `repo-skill-audit` |

## 判定手順

1. ユーザー依頼を「何をしたいか」と「何をしてはいけないか」に分ける。
2. 現在のauthorityを確認する。
   - 承認済み計画があるか。
   - review結果や検証証跡があるか。
   - 人間判断待ちがあるか。
3. すでにある成果物を確認する。
   - 調査結果、計画、実装証跡、検証証跡、review結果、triage結果、handoff packet。
4. Routing Tableから、次に実行すべきskillを1つ選ぶ。
   - 1つに絞れない場合は、主要候補と代替候補を分ける。
   - 実行順が必要な場合は、最小のsequenceを返す。
5. 次skillへ渡す入力、足りない入力、止まる条件をまとめる。

## 優先順位

- 計画未承認なら、実装へ進まず `implementation-plan-gate`、`decision-clarification-workflow`、または human decision へ戻します。
- 実装前に事実不足があるなら、計画より先に `investigation-workflow` を選びます。
- `verification-workflow` が必要だがrepo内 `test_runner` が未整備なら、検証へ進まず `test-runner-scaffold` を選びます。
- 実装済みで検証証跡がないなら、reviewより先に `verification-workflow` を選びます。
- `reviewable-gate-review` が必要だがrepo内reviewable gate agentが未整備なら、review判定へ進まず `specialist-reviewer-scaffold` を選びます。
- 調査や計画にドキュメント根拠がなく、期待動作やscopeの根拠が弱いなら、実装やreviewより先に `investigation-workflow` または `implementation-plan-gate` へ戻します。
- 文書群そのものの整合、古い前提、未決事項、実装や検証手順との食い違いを横断点検する依頼なら、実装や計画を始めず `project-doc-consistency-audit` を選びます。
- review指摘が複数混ざっているなら、直接実装せず `post-review-fix-triage` を選びます。
- 次agentや次sessionへ渡すこと自体が目的なら、対象workflowを実行せず `workflow-artifact-handoff` を選びます。
- repo固有agentやrepo固有skillが未整備で作成が目的なら、実行workflowではなく該当するscaffoldを選びます。
- 公開前点検や整合確認が目的なら、修正せず `repo-skill-audit` を選びます。

## 出力形式

```md
# Workflow Routing

## Status

routing_status: ready / blocked

## Request

- user intent:
- current stage:
- explicit do not:

## Recommended Workflow

- primary skill:
- reason:
- confidence: high / medium / low

## Alternative Workflows

- skill:
  when to use:

## Required Inputs

- input:
  status: available / missing / optional
  source:

## Suggested Sequence

- step:
  skill:
  handoff:

## Stop Conditions

- condition:
  next owner:

## Next Prompt

- prompt:
```

## 禁止事項

- routing先のworkflowをこのskill内で実行しない。
- ファイルを作成または更新しない。
- 実装、テスト更新、検証実行、review判定を始めない。
- 未承認計画を承認済みとして扱わない。
- 不足入力を推測で埋めて、次workflowへready扱いしない。
- すべてのskillを列挙して人間へ丸投げしない。primaryを1つ選び、必要な場合だけ代替を示す。

## 完了報告

最後に次を報告します。

- `routing_status`
- primary skill
- 必要な入力
- blockedの場合の不足物
- 次に使うprompt
