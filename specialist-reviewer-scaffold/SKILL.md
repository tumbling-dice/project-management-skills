---
name: specialist-reviewer-scaffold
description: ユーザーが自然文で、repo固有の専門reviewer、reviewable gate用custom agent、専門review routing、review用skillやagent定義を作りたいと頼んだ場合に使う。workflow-router のrouting結果、または $specialist-reviewer-scaffold の明示でも使う。repo構成、既存AGENTS.md、.codex/skills、.codex/agents、リスク領域を調査し、責務・リスク・入力証跡ベースでreviewable gate agent、専門reviewer候補、routing文書、repo内skill、custom agent定義を提案または作成する。差分そのもののreviewには使わない。
---

# Specialist Reviewer Scaffold

このskillは、repoごとに必要な専門reviewerを設計し、repo内skillやcustom agent定義として整備するためのscaffoldです。共通skill側では個別の言語、framework、product名を列挙しません。専門reviewerは、そのrepoの構成、リスク、レビュー証跡に基づいて作ります。

## 目的

`reviewable-gate-review` は、差分がレビュー可能か、どの専門reviewが必要かを判定する入口です。実PJではMain Agentが直接実行せず、repo内にscaffoldされた reviewable gate用custom agentが実行します。このskillは、そのagentと、判定先となるrepo固有の専門reviewerを作るために使います。

## 使う場面

- `reviewable-gate-review` を実行するrepo-local custom agentを用意したい。
- `reviewable-gate-review` から呼び出す専門reviewerをrepo内に用意したい。
- 実装者と同じ文脈で判断するとバイアスが出やすい領域を独立reviewerにしたい。
- 既存の `.codex/skills` や `.codex/agents` を整理し、review routingを明文化したい。
- repoの実装領域、データ境界、UI、検証、release判断などを責務別にreviewできるようにしたい。

## 使わない場面

- すでに差分があり、その差分自体をreviewする場合。
- 特定領域のreview本文をここに直接書きたい場合。
- すべての技術領域にcustom agentを量産したい場合。

## 基本方針

- 共通skillには、言語名、framework名、product名のblacklist / whitelistを書かない。
- repo固有の専門性は、repo内skillまたはcustom agent定義へ閉じ込める。
- 分類軸は、技術名ではなく責務、リスク、証跡で切る。
- custom agentは必要な場合だけ作る。bias分離が不要ならrepo内skillだけでよい。
- reviewable gate本体は証跡と入口条件を見る。repo-local reviewable gate agentがこれを実行する。専門reviewerは深い領域判断を見る。
- 作成する専門reviewerは、`$reviewable-gate-review` から渡される証跡を受け取り、gate互換の判定を返せるようにする。
- 専門reviewerは検証証跡を判断する。検証コマンドの実行や証跡生成は担当しない。
- 検証専用agentが必要な場合は `$test-runner-scaffold` を使い、このskillでreviewerとして作らない。

## 調査手順

1. repoの既存指示を確認する。
   - `AGENTS.md`
   - `.codex/config.toml`
   - `.codex/skills/*/SKILL.md`
   - `.codex/agents/*`
   - `docs/review/` または同等のreview文書
2. repoの主要な変更領域を把握する。
   - UI / user flow
   - API / service / domain logic
   - data model / persistence / migration
   - auth / permission / tenant / privacy
   - external input / file / import / export
   - build / deploy / config / observability
   - tests / E2E / visual evidence（実行ではなく証跡review）
3. 既存reviewerやskillで足りる領域を特定する。
4. bias分離が必要な領域を特定する。
5. repo内skillで十分なものと、custom agentが必要なものを分ける。
6. `reviewable-gate-review` を実行するrepo-local custom agentと、そこから呼び出しやすい専門review routingを作る。

## Reviewer設計単位

専門reviewerは、次の情報で定義します。

- `name`: repo内で使う短い名前
- `purpose`: 何を判断するreviewerか
- `trigger`: どの変更や証跡があると呼ぶか
- `inputs`: reviewerに渡す証跡
- `checks`: 何を見るか
- `does_not_do`: 何を判断しないか
- `output`: finding、blocking / non-blocking、人間判断が必要な点
- `handoff`: NG時の戻り先
- `reviewable_gate_compatibility`: `$reviewable-gate-review` の入力証跡をどう受け取り、どのgate互換出力を返すか

## custom agentを作る基準

次に該当する場合だけ、custom agent定義を提案します。

- 実装者バイアスを避ける必要がある。
- read-onlyで差分、計画、検証結果だけを見せたい。
- 専門reviewの観点が長く、毎回promptへ書くと漏れやすい。
- review結果をblocking / non-blocking / human decisionに分けたい。
- repo内skillだけでは、実行者の役割分離が足りない。

該当しない場合は、repo内skillだけを作ります。

検証コマンド実行を分離したい場合は、専門reviewerではなく `test_runner` の責務です。その場合は `$test-runner-scaffold` でrepo内agentとverification手順を作ります。

## 作成する成果物

repoの慣習に従います。慣習がなければ次を推奨します。

- `.codex/skills/<reviewer-name>/SKILL.md`
- `.codex/agents/reviewable_gate_reviewer.toml` またはrepo慣習に沿った同等のreviewable gate agent定義
- `.codex/agents/<reviewer-name>.toml`
- `docs/review/specialist-review-routing.md`

`docs/review/specialist-review-routing.md` は任意です。既にreview routingが `AGENTS.md` や別文書にある場合は、そこへ最小追記します。

## repo内skillの内容

repo内review skillには、次を含めます。

- このrepoでの責務
- 呼び出す条件
- 入力として必要な証跡
- blocking findingの条件
- non-blocking findingの条件
- 判断しないこと
- `reviewable-gate-review` へ返す要約形式
- gate互換の入力と出力

共通skillの内容を長く複製しません。repo固有の観点だけを書きます。

gate互換の入力は、少なくとも次を受け取れる形にします。

- 承認済み計画、または人間が承認した変更範囲
- diffまたはpatch
- 変更ファイル一覧
- 追加または更新したテスト
- 実行した検証コマンドと結果
- 未実行検証の理由とリスク
- 非対象範囲
- 権限、tenant、PII、secret、ログ、外部入力などのrisk notes

gate互換の出力は、少なくとも次を含めます。

- `status: pass / needs-specialist-review / blocked`
- blocking finding
- non-blocking finding
- 人間判断が必要な点
- 次の戻り先
- `$reviewable-gate-review` へ戻す要約

## custom agent定義の内容

custom agent定義には、次を含めます。

- reviewable gate用agentは、`$reviewable-gate-review` をgoverning workflowとして使うこと
- reviewable gate用agentは、Main Agentや実装者の長い会話履歴を前提にせず、承認済み計画、diff、変更ファイル、テスト、検証証跡、非対象範囲、risk notesだけで判定すること
- read-onlyを基本にすること
- 親や実装者の長い会話履歴を前提にしないこと
- 入力証跡だけで判断すること
- ファイル編集や修正をしないこと
- review対象外の領域へ判断を広げないこと
- repo内review skillを読み込むこと
- `$reviewable-gate-review` の証跡入力と判定状態に互換なreview結果を返すこと
- subagentとして呼び出す場合は、`subagent-execution` またはrepo内の同等規約に従うこと
- `done` / `blocked` はsubagent応答状態として使い、review判定はその内側の結果として返すこと

agent定義の形式はrepoの既存 `.codex/agents` に合わせます。既存形式がない場合は、まず提案だけを行い、ユーザー確認後に作成します。この制限はcustom agent定義だけに適用します。ユーザーがrepo内skill作成を求めている場合は、既存 `.codex/skills` がなくても `.codex/skills/<reviewer-name>/SKILL.md` を作成します。filesystem権限やrepo制約でrepo内skillを作れない場合は、docs-onlyの代替成果物へ黙って落とさず、作成不能理由、作るべきpath、作成予定内容を `blocked` として報告します。

## review routingの内容

routing文書またはAGENTS.md追記には、次を含めます。

- `reviewable-gate-review` が入口であること
- 実PJでは、Main Agentが `reviewable-gate-review` を直接実行せず、repo-local reviewable gate agentへ委譲すること
- Gateで専門reviewが必要と判定された場合の呼び出し先
- 各専門reviewerのtrigger
- 渡す入力証跡
- NG時の戻り先
- 検証証跡が不足している場合に `test_runner` またはverification workflowへ戻す条件

戻り先の例:

- 検証未実行: `verification-workflow` またはrepo内の `test_runner`
- 実装ミス候補: `implementation-execution-workflow`
- テスト方針不足、調査不足: `implementation-prep-workflow`
- 非対象範囲、security、release判断: human decision

## 禁止事項

- 共通skill側へ個別の技術名やproduct名を増やし続けない。
- repo調査なしでreviewer名や責務を決めない。
- custom agentを必要以上に増やさない。
- 実装者と同じ会話文脈を専門reviewerの根拠にしない。
- reviewerに修正、テスト実行、検証証跡生成まで担当させない。
- 検証専用agentを作る場合は `$test-runner-scaffold` を使い、このskillの専門reviewerとして混ぜない。

## 出力ルール

- まず既存reviewerと不足領域を一覧にする。
- 作成するrepo内skill / custom agent / routing文書を提案する。
- ユーザーが作成を求めている場合だけ、最小セットを作成する。
- Codexでファイルを作成または更新する場合は `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。

## 完了報告

最後に次を報告します。

- 調査した既存指示やreviewer
- 作成または更新したファイル
- 追加したreviewerの責務
- `reviewable-gate-review` からのrouting方法
- custom agentを作った理由、または作らなかった理由
- 人間が判断する点
