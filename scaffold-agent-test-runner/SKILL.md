---
name: scaffold-agent-test-runner
description: "repo固有の検証専用 `test_runner` custom agentとverification Skill／文書を設計・作成する。コマンド、権限、artifact、timeout、失敗時の戻り先を調査するが、検証実行や修正は行わない。"
---

# scaffold-agent-test-runner

このskillは、repoごとに `test_runner` custom agent を用意するためのscaffoldである。共通skill側では特定repoのコマンドを固定しない。検証コマンド、必要な権限、artifact、timeout、失敗時の扱いはrepo内skillまたはrepo内文書へ閉じ込める。

## 目的

`test_runner` は、実装者とは別の役割として検証コマンドを実行し、結果を証跡として返すagentである。修正、テスト更新、原因調査の深掘り、レビュー判定は担当しない。

このskillは、次を整備するために使う。

- repo固有の `test_runner` custom agent
- `test_runner` が読むrepo内verification skillまたは検証手順文書
- taskごとの `docs/work/<task-id>.state.json` の `commands` を入力にできる接続
- `$wf-verify` から `test_runner` へ委譲できる入力契約と戻り値
- `subagent-orchestration` に従った、Main Agent から `test_runner` への委譲形式
- 検証失敗、権限不足、環境不備、flaky疑いの戻り先

## 使わない場面

- いま差分に対して検証コマンドを実行するだけの場合。
- 検証失敗の修正を行う場合。
- 専門reviewの判定を行う場合。
- repo調査なしで共通の `test_runner` を全repoに配布したい場合。

## 基本方針

- `test_runner` はrepo内custom agentとして作る。
- 共通skillは、検証専用agentを作る手順と安全条件だけを持つ。
- Main Agent からの委譲は `subagent-orchestration` に従う。
- `$wf-verify` からの委譲を主な入口として扱い、作成物にはその接続方法を明記する。
- `test_runner` の実行規約は `subagent-execution` に従う。
- 具体的な検証コマンドのsource of truthはrepo内skillまたはrepo内文書に置く。taskごとの実行予定と結果は、state fileの `commands` に記録できる形にする。
- `test_runner` は委譲されたverificationだけを実行する。
- `test_runner` はrepo-tracked fileを編集しない。
- テスト実行でcache、build output、log、screenshotなどが出る可能性があるため、sandboxは原則 `workspace-write` を検討する。
- snapshot更新、golden更新、fixture再生成、migration、deploy、依存関係更新などは、明示承認なしに実行させない。

## 調査手順

1. repoの既存指示を確認する。
   - `AGENTS.md`
   - `.codex/config.toml`
   - `.codex/agents/*`
   - `.agents/skills/*/SKILL.md`
   - 検証、review、CI、開発環境に関する文書
2. 検証コマンドのsource of truthを確認する。
   - project manifest
   - build / test / lint / typecheck / E2E / visual確認の設定
   - CI workflow
   - 既存の開発用script
3. コマンドを分類する。
   - 通常実行してよい検証
   - 時間がかかる検証
   - dev server、localhost、network、GUI、外部service、sandbox権限が必要な検証
   - artifactやcacheを生成する検証
   - 明示承認が必要な検証
   - 実行禁止または人間判断が必要な操作
4. 失敗時の分類を決める。
   - 実装差分に起因する失敗
   - テスト期待値やfixtureの不整合
   - 環境、依存関係、権限、sandbox制約による失敗
   - flaky疑い
   - コマンド不明、前提不足、委譲範囲外
5. subagent実行規約を確認する。
   - 共通の `subagent-orchestration`
   - 共通の `subagent-execution`
   - repo内に同等または上書きのsubagent実行skillがある場合はその内容
6. `wf-review` が消費できる検証証跡形式を決める。

## 作成する成果物

repoの慣習に従う。慣習がなければ次を推奨する。

- `.codex/agents/test_runner.toml`
- `.agents/skills/<repo-or-purpose>-wf-verify/SKILL.md`
- `docs/contract/verification-commands.md`

repo内verification skillと検証文書の両方を作る場合は、重複を避ける。通常は、agentが読む詳細手順をrepo内skillに置き、人間向けの一覧や運用メモをdocsへ置きる。

## `test_runner` agent定義に含める内容

custom agentを作る前に、`$subagent-orchestration` の `references/custom-agent-schema.md` を読み、現行TOML schema、model選択、sandbox境界を適用する。

`test_runner` のcustom agent定義には、次を含める。

- agent名は `test_runner` にする。
- 役割は検証コマンド実行と結果報告に限定する。
- Main Agentや実装者の長い会話履歴を前提にしない。
- 委譲文、repo内verification skill、必要なrepo指示だけを根拠にする。
- product code、test code、docs、設定ファイルを編集しない。
- 失敗しても修正しない。
- snapshot更新、golden更新、fixture再生成、依存関係更新、migration、deployは実行しない。ただし委譲文とrepo手順で明示承認されている場合を除く。
- 権限昇格が必要な検証は、repo内手順に従って理由つきで扱う。
- 実行したコマンド、終了状態、重要ログ、artifact、未実行理由を報告する。
- state fileの `commands.status` / `commands.result` へ反映できる形で結果を返す。
- 結果状態は `subagent-execution` に従い、`done` または `blocked` として扱う。
- `$wf-verify` のDelegation Packetを受け取り、検証証跡へ統合できる形式で返すこと。

agent定義からは、共通の `subagent-execution` またはrepo内の同等skillを読み込ませる。repo内skillで上書きする場合も、`done` / `blocked` とscope制限は維持する。

既存の `.codex/agents` 形式がない場合でも、ユーザーが作成を求めているなら `.codex/agents/test_runner.toml` を作成する。既存形式がある場合はそれに合わせる。filesystem権限やrepo制約で作成できない場合は、docs-onlyの代替成果物へ黙って落とさず、作成不能理由、作るべきpath、作成予定内容を `blocked` として報告する。

## repo内verification skillに含める内容

repo内verification skillには、次を含める。

- このrepoで使う検証コマンド一覧
- 各コマンドの目的
- 実行条件
- 想定所要時間
- 生成されるartifactやcache
- sandbox権限、dev server、localhost、network、外部serviceなどの要否
- 失敗時にMain Agentへ返すログ範囲
- retryしてよい条件
- retryしてはいけない条件
- 実行禁止または人間承認が必要な操作
- `$wf-verify` からのDelegation Packetを受け取る条件
- state fileの `commands` から渡されたcommandを扱う条件
- `wf-review` へ渡す検証証跡形式
- 検証結果として返すrepo固有の報告項目

コマンド本文を複数箇所へ複製しない。既存のscriptやCIがsource of truthなら、その参照と用途を書く。

## Delegation Packetへの追加

Main Agent から `test_runner` へ渡す委譲文は、`subagent-orchestration` の Delegation Packet を使う。`Agent`、`Scope`、`Goal`、`Do not`、`Evidence`、`Deliver`、`Done when` の順を維持する。`spawn_agent` 側は `fork_turns: none` を使う。

検証実行では、各欄に次を入れる。

```md
# Delegation Packet

Agent: test_runner

## Scope

- 対象差分:
- 対象外:
- existing session id:
- recall mode: initial / recall / new-session-with-reason

## Goal

- 委譲された検証コマンドを実行し、結果を証跡として返す。

## Do not

- product code、test code、docs、設定ファイルを編集しない。
- 明示されていない検証へ広げない。
- snapshot更新、golden更新、fixture再生成、依存関係更新、migration、deployを実行しない。

## Evidence

- previous_test_runner_session_id:
- new_session_reason:
- command:
  reason:
  timeout:
  requires_escalation: yes / no / unknown
- expected success:
- known warnings:
- artifact:
- failure log needed:

## Deliver

- `Status: done` または `Status: blocked` で始める。
- current session id、initial / recall、session reuse有無、新session理由を返す。
- 実行したcommand、result、duration、重要ログ、artifact、warning、未実行理由、state fileへ反映するstatus/resultを返す。

## Done when

- 指定された検証が完了し、結果と証跡が返せる。
- 権限、環境、scope不足で続行できない場合は `blocked` を返す。
```

実行コマンドが空の場合、`test_runner` はrepo内verification skillから候補を提案して `blocked` を返す。推測で広い検証を実行しない。

## 報告形式

`test_runner` の報告形式はrepo内verification skillまたは委譲文で指定する。指定がない場合は、検証専用agentとして次の項目を含める。

```md
# Verification Result

Status: done / blocked
Session: <current session id>
Session mode: initial / recall / new-session-with-reason
Previous session: <id or none>
New session reason: <allowed reason or none>
Scope handled: <検証した差分、command、responsibility>
Result: <検証結果の要約>
Verification: <実行したcommand、result、duration、重要ログ、artifact、warning>
Out-of-scope findings: <範囲外で見つけた課題。なければ none>

Blockedの場合:
Blocking reason: <なぜ続行できないか>
What is missing: <不足している情報 / 権限 / 前提 / 追加scope>
Requested action from Main Agent: <Main Agentに補ってほしいこと>
```

検証失敗がある場合は、`Result` または `Verification` に failure classification と次の戻り先を含める。

## 失敗時の戻り先

失敗や未実行があった場合は、原因の種類ごとに戻り先を分ける。

- 実装差分に起因する失敗: `wf-implement`
- テスト方針、検証範囲、期待値、原因の不明確さ: `wf-explore`
- 検証証跡は揃ったがreview判定が必要: `wf-review`
- sandbox、権限、外部service、secret、破壊的操作の承認: human decision

`test_runner` 自身は、失敗を修正しない。

## 禁止事項

- repo調査なしで `test_runner` の検証コマンドを決めない。
- 共通skill側へ特定repoのコマンドを固定しない。
- `test_runner` に修正、テスト更新、snapshot更新、review判定を担当させない。
- 実行していない検証を実行済みとして報告しない。
- sandbox権限不足や環境不備を、根拠なくアプリ不具合として扱わない。
- 破壊的操作、deploy、本番データ操作、secret取得を検証コマンドとして実行しない。

## 出力ルール

- まず既存の検証コマンド、agent、skill、docsを整理する。
- `test_runner` に必要なrepo固有ルールを一覧にする。
- 作成するファイルを提案する。
- ユーザーが作成を求めている場合だけ、最小セットを作成する。
- Codexでファイルを作成または更新する場合は `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。

## 完了報告

最後に次を報告する。

- 調査した既存指示、agent、skill、検証文書
- 作成または更新したファイル
- `test_runner` の責務
- repo内verification skillまたは検証文書のsource of truth
- 権限昇格が必要な検証
- 実行禁止または人間承認が必要な操作
- `wf-review` へ渡す証跡形式
