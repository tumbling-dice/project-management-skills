---
name: handoff
description: ユーザーが $handoff を明示した場合だけ使う。作業成果物を、次のAIセッションが読めるhandoff packetへ整理する。長い作業文脈を圧縮し、authority、入力証跡、未確認事項、非対象範囲、再開時のownerを明確にする。実装、検証、review判定は行わない。
---

# handoff

このskillは、作業成果物を次のAIセッションが読めるhandoff packetに整理する。目的は、長い会話履歴や複数の `docs/work` 成果物に依存せず、次のagentが必要なauthorityと証跡だけを読めるようにすることである。

出力は人間が読む報告ではなく、次のAIがそのまま入力として読める圧縮packetにする。

## 使う場面

- 実装前準備、承認済み計画、実装証跡、検証証跡、review指摘を次セッションで読める形へ圧縮したい。
- 作業が長くなり、次のagentへ渡す文脈を圧縮したい。
- 次のCodexセッションで、会話履歴を読まずに作業を再開したい。

## 使わない場面

- 新しい事実調査を行う場合。
- 実装、テスト更新、検証実行、review判定を行う場合。
- 不足している承認をAIが補う場合。
- 複数成果物の矛盾を人間の代わりに確定する場合。

## 入力

必要に応じて次を確認する。

- 元workflowの成果物
- 承認済み計画、または人間が承認した変更範囲
- `docs/work/<task-id>.state.json` がある場合は、進捗、対象ファイル、関連ファイル、commands結果
- diff、変更ファイル、テスト、検証証跡
- review結果、triage結果
- 非対象範囲
- 未確認事項、人間判断待ち、risk acceptance
- 再開時にやりたいこと

入力が足りず再開できるpacketを作れない場合は、packetの `status: blocked` に不足物を列挙する。

## 基本方針

- 次のAIセッションに必要なauthorityと証跡だけを残す。
- 実装者の長い会話履歴、未検証の仮説、採用案を正当化する説明をauthorityにしない。
- 承認済み事項、未承認事項、非対象範囲、推測を分ける。
- 次のAIセッションが読むべきファイルと、読まなくてよい背景を分ける。
- state fileは進捗やcommands結果の証跡として扱い、authorityにはしない。
- ローカルフルパスを配布用skillやhandoff本文の前提にしない。repo内path、skill名、asset名で示す。
- 人間向けの説明、要約、見出し、読み物としての背景説明は入れない。
- 空の項目は出さない。値が不明な項目は `unknown` とせず、再開を止める場合だけ `open.blocking` に置く。

## 手順

1. 再開時の目的と、次のAIが最初に行うことを決める。
2. authorityを確認する。
   - 承認済み計画、人間承認、review結果など、次のAIが根拠にしてよいものを明記する。
3. 入力証跡を整理する。
   - 読むべき成果物、diff、検証ログ、artifact、review commentを列挙する。
4. 非対象範囲、禁止事項、未確認事項を分ける。
5. 再開時に最初に行うべきこと、止まるべき条件、完了条件をまとめる。
6. 必要ならhandoff packetを `docs/work/<task-id>-handoff.md` として保存する。

## 出力形式

packetは次のようなYAML風の構造化テキストにする。空配列、空見出し、人間向け説明文は出さない。

```yaml
handoff:
  status: ready | blocked
  task_id: <task-id>
  created_for: next-ai-session | named-agent
  goal: <what the next AI should accomplish>
authority:
  - source: <path-or-human-approval-reference>
    claim: <next AI may rely on this>
scope:
  include:
    - <in scope>
  exclude:
    - <non-goal>
must_read:
  - path: <repo-relative-path-or-artifact>
    reason: <why next AI needs it>
state:
  state_file: <repo-relative-path>
  changed_files:
    - <repo-relative-path>
  commands:
    - command: <command>
      result: passed | failed | not_run
open:
  blocking:
    - item: <what stops restart>
      owner: ai | human | named-agent
  non_blocking:
    - item: <risk or note>
      owner: <owner>
do_not_carry:
  - item: <discarded assumption or stale context>
    reason: <why>
resume:
  first_action: <what the next AI should do first>
  do_not:
    - <prohibited action>
  done_when:
    - <completion condition>
  blocked_when:
    - <stop condition>
```

`status: blocked` の場合は、`authority` や `resume` を無理に埋めず、`open.blocking` と `must_read` を中心にする。

人間がファイル保存を求めた場合、または次セッションへ渡す用途が明確な場合は、packetを `docs/work/<task-id>-handoff.md` などPJ慣習の場所へ保存する。会話上に直接返す場合も、packet以外の説明を付けない。

## 禁止事項

- 未承認の計画や未回答の判断をauthorityとして扱わない。
- 実装、検証、review判定、risk acceptanceをこのskill内で行わない。
- 必要な証跡を省いて、次のAIセッションに推測させない。
- 長い会話履歴をそのままhandoffとして渡さない。
- ローカルフルパスを配布前提の成果物に固定しない。

## 完了報告

handoff packetを保存した場合、最後の人間向け報告は保存先とstatusだけにする。packet本文の要約を重ねない。

```text
handoff: <path>
status: ready | blocked
```

保存せず会話上に返す場合は、出力形式のpacketだけを返す。
