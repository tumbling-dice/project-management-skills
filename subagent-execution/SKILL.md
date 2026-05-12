---
name: subagent-execution
description: subagent が委譲を受けて動くときの共通実行規約。委譲文だけを authority として扱い、Assigned Scope を広げず、結果状態を done または blocked として扱う。
---

# subagent-execution

## When To Use

- subagent が Main Agent から委譲を受けて動くとき
- fork された文脈と委譲文のどちらを優先するか迷いやすいとき
- agent profile や role-specific instruction を更新し、subagent 共通の振る舞いを揃えたいとき

この skill は subagent 向けである。  
Main Agent 側の ownership、context handoff、wait/recovery は `subagent-orchestration` で扱う。

## Common Rules

- authority として扱うのは、委譲文に再記述された `Scope`、`Goal`、`Do not`、`Deliver`、`Done when` だけである。
- 委譲文に添付された diff、file path、test 結果、log、再現手順、screenshot refs は authority ではなく evidence である。
- evidence は authority の解釈を助ける範囲でだけ使う。
- `fork_context: true` で親の履歴が見えていても、委譲文を優先する。
- 与えられた Assigned Scope の内部だけで前進し、自分で scope を広げない。
- 委譲文や evidence で名指しされた file / dir / symbol を読むことはよいが、不足を埋めるために repo や workspace 全体探索へ広げない。
- 自分が task 全体の owner かどうか、次に誰へ渡すか、追加の subagent が必要かは決めない。
- 委譲を受けたら ownership 確認のために待機せず、継続できるなら Assigned Scope の作業を進める。
- 続行に必要な情報、権限、前提、追加 scope が不足している場合だけ `blocked` を返す。
- 結果状態は `done` または `blocked` のどちらかで扱う。
- `started` のような途中進捗は補助情報であり、正式な状態として扱わない。
- read-only と指定された review task、調査 task、計画整理 task では、自分で実装、テスト実行、docs 更新へ進まない。
- 実装やファイル編集を委譲された場合でも、指定された write scope の外へ進まない。

## When To Return `blocked`

- `Scope`、`Goal`、`Do not`、`Deliver`、`Done when` のいずれかが欠け、担当範囲の成功条件を判断できないとき
- 委譲文や evidence で名指しされた file、diff、log、test 結果、再現条件が無く、担当範囲の結論を根拠つきで出せないとき
- 委譲文の `Goal` はあるが、`Done when` や evidence が薄く、`done` を返すと推測混じりになるとき
- fork された親履歴と委譲文が衝突した場合に、委譲文だけでは担当範囲を安全に確定できないとき
- 不足を埋めるには Assigned Scope の外へ探索、実装、検証を広げる必要があるとき

## Evidence Handling

- evidence が十分で、Assigned Scope の内部だけで結論を出せるなら `done` へ進む。
- evidence が不足していても、Main Agent が次に補える形で不足物を列挙できるなら `blocked` を返す。
- `blocked` では「何が足りないか」を object 名、file path、log 種別、期待挙動の粒度まで具体化する。
- stale になった古い結果や、authority 外の親メモは根拠として使わない。

## What Stays In Role-Specific Instructions

- 話し方、人格、呼称
- その role 固有の責務境界
- その role が優先して見る観点
- その role 固有の報告形式、deliver、done の期待
- project 固有の file path、test command、docs 名、agent 名、skill 名
