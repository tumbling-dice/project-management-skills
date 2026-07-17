---
name: subagent-orchestration
description: Main Agentがsubagentへ独立した作業を委譲するときに使う共通契約。ownership、context handoff、delegation packet、`done`／`blocked`、steering、wait、stale resultを定める。subagent側の実行には使わない。
---

# subagent-orchestration

このskillはMain Agent向けである。subagent側の共通実行規約は `subagent-execution` を前提とする。

## Ownership

- Task 全体の owner は Main Agent である。
- Scope の owner を決める権限は Main Agent のみにある。
- 最終的な採用判断、統合、ユーザーへの報告責任は Main Agent が持つ。
- subagent は delegated scope の範囲だけを担当し、自分で owner や次担当を決めない。
- 実装やファイル編集を委譲する場合は、Main Agent が write scope と衝突しない境界を明示する。
- read-only の調査、review、計画整理、検証実行だけを委譲する場合は、subagent が実装や docs 更新へ進まないことを明示する。
- 同じ file / dir / symbol / responsibility を複数 subagent に同時委譲しない。
- test 実行を委譲しても、何を実行するか、結果をどう扱うか、失敗時に何をするかの責任は Main Agent が持つ。

## Context Handoff

- `spawn_agent` の `fork_turns` は原則 `none` とする。直近会話がauthorityとして必要な場合だけ、必要最小限のturn数を明示する。
- subagent へ渡す authority は、委譲文に再記述した `Scope`、`Goal`、`Do not`、`Deliver`、`Done when` だけに絞る。
- diff、file path、test 結果、log、再現手順、screenshot refs のような添付物は authority ではなく evidence として渡す。
- 親 agent の途中思考、別案比較、口調設定、未採用の仮説は、委譲文へ明記していない限り authority ではない。
- review subagent へは diff、対象 file、test 結果、必要なら screenshot refs だけを渡す。
- evidence に含まれない材料を subagent が推測で取りに行く前提にしない。

## Delegation Packet

委譲文は次の順で固定すると、subagent が読み違えにくい。

- `Agent`
- `Scope`
- `Goal`
- `Do not`
- `Evidence`
- `Deliver`
- `Done when`

`Evidence` には、subagent が `done` / `blocked` を判断するための材料だけを入れる。

- 調査: 対象 file / dir / symbol、観測してほしい観点、必要なら narrow な integration point、関連 test / fixture / docs
- 計画整理: 対象 requirement / complaint / issue、候補 docs、同期対象の planning artifact
- review: diff、対象 file、test 結果、必要なら screenshot refs
- test 実行: 実行コマンド、期待成功条件、既知 warning、timeout、権限要否、artifact、停止条件の扱い
- 実装: write scope、変更してよい file / dir、触れてはいけない範囲、期待する verification

対象 file だけでは contract を立証できないなら、Main Agent が必要最小限の integration file や fixture を `Evidence` に明示追加する。subagent に暗黙探索させない。

`Done when` は「何が揃えば `done` か」だけでなく、「何が欠けていたら `blocked` へ倒してよいか」が逆算できる粒度で書く。

`Deliver` には、そのroleに必要な成果物、根拠、報告項目を書く。具体的な報告形式はrole-specific skillまたは委譲文で指定する。

## Completion State

- Main Agent は subagent の結果状態を `done` または `blocked` のどちらかとして扱う。
- `done` は delegated scope の結果要約と根拠を返す。
- `blocked` は不足情報、停止理由、Main Agent に求める対応だけを返す。
- `started` のような途中報告は補助情報であり、統合判断の材料にしない。

## Wait And Recovery

- Main Agent は agent ID と delegated scope を対で管理する。
- 複数scopeが独立し、write ownershipが重ならない場合だけ並列spawnする。必要なagentを起動し切ってから結果を待ち、統合条件を満たすまで最終判断しない。
- 次の一手が subagent の結果に依存するなら、推測で先回りせず待つ。
- `wait_agent` 未完了だけを理由に、同じ scope の二重委譲や再催促をしない。
- 実行中agentへ前提変更を即時通知する場合は `send_message`、完了後またはidle中agentへ新しいturnを依頼する場合は `followup_task` を使う。
- 進行中の作業を取り消す必要がある場合だけ `interrupt_agent` を使い、返された状態を確認してから再委譲する。
- stale result を避けるため、入力 docs、diff、test 結果、delegated scope が Main Agent 側で更新されたら、古い結果は破棄または再実行する。
- ここでいう `破棄` は、古い結果を統合判断、次委譲の authority、review 依頼の前提に使わないことを指す。
- delegated scope または evidence が実質的に変わったなら、新しいtaskとしてfreshな委譲文を作り直す。実行中agentの旧taskと衝突する場合はinterruptしてから再委譲する。

## Reusable Subagent Sessions

workflow固有の規則で同じsubagent sessionの再利用が定義されている場合だけ、Main Agent は初回の agent ID を保持し、後続packetをその既存sessionへ送る。すべてのsubagentを既定で再利用するわけではない。

再利用が定義されたworkflowでは、後続packetに前回session id、今回の追加scope、変更されたevidence、再実行する観点を入れる。新しいsessionへ切り替える場合は、workflowが許可した例外理由を記録する。理由がない新sessionは、recall behaviorを立証できない結果として扱う。
