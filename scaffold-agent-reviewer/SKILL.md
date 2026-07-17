---
name: scaffold-agent-reviewer
description: repo固有の専門reviewer、pre-implementation review、reviewable gate、review routing用のSkillとcustom agentを設計・作成する。AGENTS、`.agents/skills`、`.codex/agents`、リスク領域を調査するが、差分review自体には使わない。
---

# scaffold-agent-reviewer

このskillは、repoごとに必要な専門reviewerを設計し、repo内skillやcustom agent定義として整備するためのscaffoldである。共通skill側では個別の言語、framework、product名を列挙しない。専門reviewerは、そのrepoの構成、リスク、レビュー証跡に基づいて作る。

## 目的

`wf-explore` は、実装前計画に対して pre-implementation review を常に行い、Main Agent が影響範囲から委譲先reviewerを選ぶ。`wf-review` は、差分がレビュー可能か、どの専門reviewが必要かを判定する入口である。実PJではMain Agentが証跡なしに直接判定せず、repo-local supplementで定義されたreviewer routingやreviewable gate実装を使う。このskillは、そのrouting、gate実装、判定先となるrepo固有の専門reviewerを作るために使う。

## 使わない場面

- すでに差分があり、その差分自体をreviewする場合。
- 特定領域のreview本文をここに直接書きたい場合。
- すべての技術領域にcustom agentを量産したい場合。

## 基本方針

- 共通skillには、言語名、framework名、product名のblacklist / whitelistを書かない。
- repo固有の専門性は、repo内skillまたはcustom agent定義へ閉じ込める。
- 分類軸は、技術名ではなく責務、リスク、証跡で切る。
- custom agentは必要な場合だけ作る。bias分離が不要ならrepo内skillだけでよい。
- reviewable gate本体は証跡と入口条件を見る。repo-local reviewable gate実装がこれを担当する。専門reviewerは深い領域判断を見る。
- pre-implementation reviewでは、専門reviewerは確定前の計画メモに対する実装時の注意点、後続review観点、計画上の懸念、今回の非対象範囲を返す。修正命令や実装可否の単独承認にはしない。
- 作成する専門reviewerは、`$wf-review` から渡される証跡を受け取り、gate互換の判定を返せるようにする。
- 専門reviewerは検証証跡を判断する。検証コマンドの実行や証跡生成は担当しない。
- 検証専用agentが必要な場合は `$scaffold-agent-test-runner` を使い、このskillでreviewerとして作らない。

## 調査手順

1. repoの既存指示を確認する。
   - `AGENTS.md`
   - `.codex/config.toml`
   - `.agents/skills/*/SKILL.md`
   - `.codex/agents/*`
   - `docs/contract/` または同等のreview文書
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
6. `wf-explore` の pre-implementation review と `wf-review` のreviewable gateから呼び出しやすい専門review routingを作る。

## Reviewer設計単位

専門reviewerは、次の情報で定義する。

- `name`: repo内で使う短い名前
- `purpose`: 何を判断するreviewerか
- `trigger`: どの変更や証跡があると呼ぶか
- `inputs`: reviewerに渡す証跡
- `checks`: 何を見るか
- `does_not_do`: 何を判断しないか
- `output`: finding、blocking / non-blocking、人間判断が必要な点
- `handoff`: NG時の戻り先
- `pre_implementation_review_compatibility`: `$wf-explore` の計画メモをどう受け取り、実装時の注意点、後続review観点、計画上の懸念、非対象範囲をどう返すか
- `reviewable_gate_compatibility`: `$wf-review` の入力証跡をどう受け取り、どのgate互換出力を返すか

## custom agentを作る基準

次に該当する場合だけ、custom agent定義を提案する。

- 実装者バイアスを避ける必要がある。
- read-onlyで差分、計画、検証結果だけを見せたい。
- 専門reviewの観点が長く、毎回promptへ書くと漏れやすい。
- review結果をblocking / non-blocking / human decisionに分けたい。
- repo内skillだけでは、実行者の役割分離が足りない。

該当しない場合は、repo内skillだけを作る。

検証コマンド実行を分離したい場合は、専門reviewerではなく `test_runner` の責務である。その場合は `$scaffold-agent-test-runner` でrepo内agentとverification手順を作る。

## 作成する成果物

repoの慣習に従う。慣習がなければ次を推奨する。

- `.agents/skills/<reviewer-name>/SKILL.md`
- `.codex/agents/reviewable_gate_reviewer.toml` またはrepo慣習に沿った同等のreviewable gate agent定義
- `.codex/agents/<reviewer-name>.toml`
- `docs/contract/specialist-review-routing.md`
- `docs/contract/reviewable-gate.md` またはrepo慣習に沿ったgate summary手順

`docs/contract/specialist-review-routing.md` は任意である。既にreview routingが `AGENTS.md` や別文書にある場合は、そこへ最小追記する。

## repo内skillの内容

repo内review skillには、次を含める。

- このrepoでの責務
- 呼び出す条件
- 入力として必要な証跡
- pre-implementation reviewで返す実装時の注意点、後続review観点、計画上の懸念、非対象範囲
- blocking findingの条件
- non-blocking findingの条件
- 判断しないこと
- `wf-explore` の計画メモへ返す要約形式
- `wf-review` へ返す要約形式
- gate互換の入力と出力

共通skillの内容を長く複製しない。repo固有の観点だけを書く。

gate互換の入力は、少なくとも次を受け取れる形にする。

- 承認済み計画、または人間が承認した変更範囲
- diffまたはpatch
- 変更ファイル一覧
- 承認済み計画と同じtask-idのstate fileがある場合は、対象ファイル、関連ファイル、commands結果
- 追加または更新したテスト
- 実行した検証コマンドと結果
- 未実行検証の理由とリスク
- 非対象範囲
- 権限、tenant、PII、secret、ログ、外部入力などのrisk notes

gate互換の出力は、少なくとも次を含める。

- `status: pass / needs-specialist-review / blocked`
- blocking finding
- non-blocking finding
- 人間判断が必要な点
- 次の戻り先
- `$wf-review` へ戻す要約

## custom agent定義の内容

custom agentを作る前に、`$subagent-orchestration` の `references/custom-agent-schema.md` を読み、現行TOML schema、model選択、sandbox境界を適用する。

custom agent定義には、次を含める。

- reviewable gate用agentを作る場合は、`$wf-review` をgoverning workflowとして使うこと
- pre-implementation reviewerとして呼ばれる場合は、`$wf-explore` の計画メモを入力とし、実装前の専門助言だけを返すこと
- reviewable gate用agentは、Main Agentや実装者の長い会話履歴を前提にせず、承認済み計画、diff、変更ファイル、テスト、検証証跡、非対象範囲、risk notesだけで判定すること
- read-onlyを基本にすること
- 親や実装者の長い会話履歴を前提にしないこと
- 入力証跡だけで判断すること
- ファイル編集や修正をしないこと
- review対象外の領域へ判断を広げないこと
- repo内review skillを読み込むこと
- `$wf-review` の証跡入力と判定状態に互換なreview結果を返すこと
- subagentとして呼び出す場合は、`subagent-execution` またはrepo内の同等規約に従うこと
- `done` / `blocked` はsubagent応答状態として使い、review判定はその内側の結果として返すこと

agent定義の形式はrepoの既存 `.codex/agents` に合わせる。既存形式がない場合でも、ユーザーが作成を求めているなら `references/custom-agent-schema.md` の必須fieldを持つ最小TOMLを作る。ユーザーがrepo内skill作成を求めている場合は、既存 `.agents/skills` がなくても `.agents/skills/<reviewer-name>/SKILL.md` を作成する。filesystem権限やrepo制約で作成できない場合は、docs-onlyの代替成果物へ黙って落とさず、作成不能理由、作るべきpath、作成予定内容を `blocked` として報告する。

## review routingの内容

routing文書またはAGENTS.md追記には、次を含める。

- `wf-review` が入口であること
- `wf-explore` では pre-implementation review を常に行い、Main Agentが影響範囲から委譲先reviewerを選ぶこと
- 実PJでは、Main Agentが証跡なしに `wf-review` を直接判定せず、repo-local reviewable gate実装を使うこと
- gate実装がcustom agent委譲か、専門reviewer結果とgate文書の照合で作るgate summaryかを明記すること
- pre-implementation reviewで各専門reviewerへ渡す計画メモの入力証跡
- Gateで専門reviewが必要と判定された場合の呼び出し先
- 各専門reviewerのtrigger
- 渡す入力証跡
- NG時の戻り先
- 検証証跡が不足している場合に `test_runner` またはverification workflowへ戻す条件

戻り先の例:

- 検証未実行: `wf-verify` またはrepo内の `test_runner`
- 実装ミス候補: `wf-implement`
- テスト方針不足、調査不足: `wf-explore`
- 非対象範囲、security、release判断: human decision

## 禁止事項

- 共通skill側へ個別の技術名やproduct名を増やし続けない。
- repo調査なしでreviewer名や責務を決めない。
- custom agentを必要以上に増やさない。
- 実装者と同じ会話文脈を専門reviewerの根拠にしない。
- reviewerに修正、テスト実行、検証証跡生成まで担当させない。
- 検証専用agentを作る場合は `$scaffold-agent-test-runner` を使い、このskillの専門reviewerとして混ぜない。

## 出力ルール

- まず既存reviewerと不足領域を一覧にする。
- 作成するrepo内skill / custom agent / routing文書を提案する。
- ユーザーが作成を求めている場合だけ、最小セットを作成する。
- Codexでファイルを作成または更新する場合は `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。

## 完了報告

最後に次を報告する。

- 調査した既存指示やreviewer
- 作成または更新したファイル
- 追加したreviewerの責務
- `wf-explore` の pre-implementation review と `wf-review` からのrouting方法
- custom agentを作った理由、または作らなかった理由
- 人間が判断する点
