---
name: workflow-artifact-handoff
description: このskillは workflow-router のrouting結果、またはユーザーが $workflow-artifact-handoff を明示した場合だけ使う。通常依頼から直接発火しない。各workflowの成果物を、次workflowへ渡せるhandoff packetへ整理する。長い作業文脈を圧縮し、authority、入力証跡、未確認事項、非対象範囲、次のownerを明確にする。実装、検証、review判定は行わない。
---

# Workflow Artifact Handoff

このskillは、各workflowの成果物を次のworkflowへ渡すためのhandoff packetに整理します。目的は、長い会話履歴や複数の `docs/work` 成果物に依存せず、次のagentや次のworkflowが必要なauthorityと証跡だけを読めるようにすることです。

## 使う場面

- 実装前準備の成果物を `implementation-prep-workflow` または後続workflowへ渡したい。
- 承認済み計画を `implementation-execution-workflow` へ渡したい。
- 実装証跡と検証証跡を `reviewable-gate-review` へ渡したい。
- review指摘を `post-review-fix-triage` または `implementation-execution-workflow` へ渡したい。
- 作業が長くなり、次のagentへ渡す文脈を圧縮したい。

## 使わない場面

- 新しい事実調査を行う場合。
- 実装、テスト更新、検証実行、review判定を行う場合。
- 不足している承認をAIが補う場合。
- 複数成果物の矛盾を人間の代わりに確定する場合。

## 入力

必要に応じて次を確認します。

- 元workflowの成果物
- 承認済み計画、または人間が承認した変更範囲
- diff、変更ファイル、テスト、検証証跡
- review結果、triage結果
- 非対象範囲
- 未確認事項、人間判断待ち、risk acceptance
- 次に実行したいworkflow

入力が足りず次workflowへ渡せない場合は、`handoff_status: blocked` として不足物を列挙します。

## 基本方針

- 次workflowに必要なauthorityと証跡だけを残す。
- 実装者の長い会話履歴、未検証の仮説、採用案を正当化する説明をauthorityにしない。
- 承認済み事項、未承認事項、非対象範囲、推測を分ける。
- 次workflowが読むべきファイルと、読まなくてよい背景を分ける。
- ローカルフルパスを配布用skillやhandoff本文の前提にしない。repo内path、skill名、asset名で示す。

## Handoff Type

次workflowに応じて、packetの種類を選びます。

- `prep-to-execution`: 実装前準備の作業コンテクストから承認後の実装へ。
- `plan-to-execution`: 承認済み計画から実装へ。
- `execution-to-verification`: 実装差分から検証へ。
- `verification-to-reviewable-gate`: 検証証跡からreview gateへ。
- `review-to-triage`: review指摘からtriageへ。
- `triage-to-execution`: triage済み指摘から再実装へ。
- `general-continuation`: 作業再開や別agentへの引き継ぎ。

## 手順

1. 次workflowとhandoff typeを決める。
2. authorityを確認する。
   - 承認済み計画、人間承認、review結果など、次workflowが根拠にしてよいものを明記する。
3. 入力証跡を整理する。
   - 読むべき成果物、diff、検証ログ、artifact、review commentを列挙する。
4. 非対象範囲、禁止事項、未確認事項を分ける。
5. 次workflowが最初に行うべきこと、止まるべき条件、完了条件をまとめる。
6. 必要ならhandoff packetを `docs/work/<task-id>-handoff.md` として保存する。

## 出力形式

```md
# Workflow Artifact Handoff

## Status

handoff_status: ready / blocked

## Handoff

- type:
- from workflow:
- to workflow:
- task id:
- created for:

## Authority

- approved plan:
- human approval:
- review decision:
- scope:
- non-goals:

## Evidence To Read

- file:
  why:
- diff:
- verification:
- review:
- artifact:

## Confirmed Facts

- fact:
  source:

## Open Items

- item:
  blocking: yes / no
  next owner:

## Do Not Carry Forward

- item:
  reason:

## Next Workflow Packet

- goal:
- inputs:
- do not:
- done when:
- blocked when:

## Next Step

- implementation-prep-workflow / implementation-execution-workflow / verification-workflow / reviewable-gate-review / post-review-fix-triage / decision-clarification-workflow / human decision
```

## 禁止事項

- 未承認の計画や未回答の判断をauthorityとして扱わない。
- 実装、検証、review判定、risk acceptanceをこのskill内で行わない。
- 必要な証跡を省いて、次workflowに推測させない。
- 長い会話履歴をそのままhandoffとして渡さない。
- ローカルフルパスを配布前提の成果物に固定しない。

## 完了報告

最後に次を報告します。

- `handoff_status`
- handoff type
- 次workflow
- 渡すauthorityと証跡
- blockedの場合の不足物
