---
name: scaffold-agent-prep-scout
description: "`wf-explore` 用のread-only prep scoutとrepo-local委譲契約を設計・作成する。AGENTS、`.agents/skills`、`.codex/agents`、work templateを調査するが、実装計画、差分review、検証実行は行わない。"
---

# scaffold-agent-prep-scout

このskillは、repoごとに `$wf-explore` の前処理を分担する read-only prep scout を設計し、repo内skillやcustom agent定義として整備するためのscaffoldである。共通skill側では個別repoのagent名、model、人格、分類語を固定しない。

## 目的

`wf-explore` は、実装前の調査、計画、修正開始可否、人間判断を1つの作業コンテクストへまとめる入口である。実PJでは、調査対象が大きい場合に read-only prep scout へ事実確認や計画候補整理を分け、Main Agent が結果を採用判断して統合すると扱いやすい。

このskillは、次を整備するために使う。

- repo固有の context scout / planning scout 相当の custom agent
- `wf-explore` から prep scout へ渡す Evidence、Deliver、Done when
- repo-local subagent orchestration / execution supplement
- `docs/work/_template.md` または同等templateへの prep scout evidence 記録欄
- `docs/work/_template.state.json` がある場合のstate fileとの分担確認
- scout未整備、起動不能、scope不一致の場合のfallbackとblocked条件

## 使わない場面

- 実装前の調査と計画そのものを行う場合。その場合は `wf-explore` を使う。
- 承認済み計画に沿って実装する場合。その場合は `wf-implement` を使う。
- 検証実行を分離したい場合。その場合は `scaffold-agent-test-runner` を使う。
- 差分reviewやreview routingを整えたい場合。その場合は `scaffold-agent-reviewer` を使う。
- 新規PJの初期文書セットを作る場合。その場合は `scaffold-project` を使う。

## 基本方針

- prep scout は read-only とし、成果物作成、docs更新、実装、test実行、採用判断、計画確定、次担当決定を担当しない。
- Task全体のowner、scope決定、採用判断、作業コンテクストへの統合、ユーザーへの報告はMain Agentが担当する。
- custom agent名はrepo-localで決める。共通推奨としては、観測事実を整理する context scout 相当と、要件や計画候補を整理する planning scout 相当を分けて考える。
- Main Agentからの委譲は `subagent-orchestration` の Delegation Packet に従う。
- scout側の実行規約は `subagent-execution` またはrepo-localの同等skillに従う。
- scoutが使えないだけで `wf-explore` を止めない。Main Agentが同じ観点を読解で補い、それでも計画確定に必要な事実、scope、risk、文書根拠が不足する場合だけblockedにする。

## 設計の既定値

迷った場合は、次の順で小さく始める。

1. 文書が薄い小規模repoでは、prep scout agent作成より先に `scaffold-project` またはrepo内template整備を検討する。
2. 既存のrepo-local workflow mapがある場合は、`wf-explore` supplementの正本をそこへ置く。workflow mapがない場合は `AGENTS.md` へ最小追記する。subagent規約が長くなる場合だけ、repo-local orchestration / execution skillへ分ける。
3. repo-local orchestration / execution skillは、既存があれば追記する。なければまず共通 `subagent-orchestration` / `subagent-execution` を参照し、repo固有のEvidence、Deliver、Done whenが長い場合だけ新設する。
4. 読む量が少ないrepoでは、prep scoutは1つにまとめてよい。source / tests / docs / ADRの事実確認と、requirements / docs/work / ADRの候補整理を分けないと混ざるrepoでは、context scout相当とplanning scout相当に分ける。
5. planning scout相当の出力は、既存要件で足りる点、採用候補、保留または却下候補、曖昧さ、docs更新候補までに留める。raw requestを直接、確定実装taskや承認済み計画へ変換しない。
6. 既存の `test_runner`、reviewable gate、specialist reviewer、verification / review docsには prep scout の責務を混ぜない。必要なら workflow map から参照するだけにする。

## 調査手順

1. repoの既存指示を確認する。
   - `AGENTS.md`
   - `.codex/agents/*`
   - `.agents/skills/*/SKILL.md`
   - `docs/contract/` またはrepo固有workflow map
   - `docs/work/_template.md` と `docs/work/_template.state.json` または同等template
   - `docs/requirements/`、ADR、review、verification文書
2. `wf-explore` のsource of truthを確認する。
   - 共通 `wf-explore`
   - repo-local supplement
   - 作業コンテクストtemplate
3. 実装前に分離したい読解範囲を分類する。
   - source / tests / fixture / integration point
   - docs / accepted requirements / ADR
   - layout contract / screen docs
   - verification docs / review routing
4. 既存agentやskillで足りる範囲を特定する。
5. prep scoutとして分ける価値がある範囲を決める。
6. scout未整備やscope不一致の場合のfallbackとblocked条件を決める。

## Scout設計単位

prep scoutは、次の情報で定義する。

- `name`: repo内で使う短いagent名
- `role_category`: context scout / planning scout / repo固有の同等分類
- `purpose`: 何を整理するagentか
- `trigger`: `wf-explore` のどの依頼やscopeで呼ぶか
- `inputs`: Main Agentから渡すevidence
- `checks`: 何を見るか
- `does_not_do`: 何を判断、実行、編集しないか
- `output`: 事実、分類、未確認事項、blocked理由
- `handoff`: blocked時にMain Agentへ求める対応
- `wf_explore_integration`: 作業コンテクストのどの欄へ統合するか

## 作成する成果物

repoの慣習に従う。慣習がなければ次を候補にする。

- `.codex/agents/<context-scout-name>.toml`
- `.codex/agents/<planning-scout-name>.toml`
- `.agents/skills/<repo>-subagent-orchestration/SKILL.md`
- `.agents/skills/<repo>-subagent-execution/SKILL.md`
- `docs/contract/workflow-map.md` への `wf-explore` supplement追記
- `docs/work/_template.md` への prep scout evidence欄

既存のrepo-local orchestration / execution skillがある場合は、重複作成せず必要な追記に留める。既存templateがある場合は、それをsource of truthとして扱い、共通templateを複製しない。prep scoutの事実、分類、未確認事項はMarkdownへ置き、state fileへ長い調査メモを入れない。

## custom agent定義の内容

custom agentを作る前に、`$subagent-orchestration` の `references/custom-agent-schema.md` を読み、現行TOML schema、model選択、sandbox境界を適用する。

prep scoutのcustom agent定義には、次を含める。

- roleはread-onlyの事実整理または計画候補整理に限定する。
- Main Agentや実装者の長い会話履歴を前提にしない。
- 委譲文、repo内supplement、指定されたevidenceだけを根拠にする。
- product code、test code、docs、設定ファイルを編集しない。
- test、lint、formatter、E2E、dev server、snapshot更新、fixture再生成を実行しない。
- 採用判断、計画確定、修正開始可否、owner、次担当を決めない。
- delegated scopeの外へ探索を広げる場合は `blocked` としてMain Agentへ不足evidenceを返す。
- 結果状態は `subagent-execution` に従い、`done` または `blocked` として返す。

既存の `.codex/agents` 形式がない場合でも、ユーザーが作成を求めているならrepo慣習に近い最小TOMLを作成する。filesystem権限やrepo制約で作成できない場合は、docs-onlyの代替成果物へ黙って落とさず、作成不能理由、作るべきpath、作成予定内容を `blocked` として報告する。

## repo-local supplementの内容

workflow map、AGENTS.md、repo-local orchestration skillのいずれかに、次を含める。

- `wf-explore` の共通本文をsource of truthとし、repo固有補足だけを置くこと
- どの依頼でどの prep scout を呼ぶか
- scoutへ渡すEvidenceの範囲
- scoutが返すDeliverと `done` / `blocked` 条件
- scout結果をMain Agentが作業コンテクストへ統合し、採用判断すること
- scout未使用、起動不能、scope不一致の場合のfallback
- Main Agentの読解補完後も不足が残る場合のblocked条件

## work templateの内容

`docs/work/_template.md` または同等templateへ欄を追加する場合は、次を記録できるようにする。

- 使用したscout名またはrole category
- 各scoutの結果状態: `done` / `blocked`
- scoutへ渡した主なevidence
- scoutが返した事実、分類、未確認事項の要約
- Main Agentが採用したevidenceと採用しなかったevidence
- scout未使用の場合の理由、Main Agentが補った確認、残る不足

templateを更新しない場合でも、`wf-explore` の作業コンテクストに同等の項目を追加できるようrepo-local supplementへ書く。state fileは進捗、対象ファイル、関連ファイル、commandsに限定し、prep scoutの要約置き場にしない。

## Delegation Packetへの接続

Main Agentから prep scout へ渡す委譲文は、`subagent-orchestration` の Delegation Packet を使う。`Agent`、`Scope`、`Goal`、`Do not`、`Evidence`、`Deliver`、`Done when` の順を維持する。`spawn_agent` 側は `fork_turns: none` を使う。

prep scout向けには、各欄に次を入れる。

```md
# Delegation Packet

Agent: <repo-local scout name>

## Scope

- 調査または整理する範囲:
- 対象外:

## Goal

- 指定されたevidenceだけを根拠に、観測事実または計画候補を整理する。

## Do not

- product code、test code、docs、設定ファイルを編集しない。
- test、lint、formatter、E2E、dev serverを実行しない。
- 採用判断、計画確定、修正開始可否、次担当を決めない。
- 明示されていない範囲へ探索を広げない。

## Evidence

- request / issue / complaint:
- files / dirs:
- docs / ADR / requirements:
- template / work artifact:

## Deliver

- `Status: done` または `Status: blocked` で始める。
- 観測事実、分類、未確認事項、採用判断が必要な点、blocked理由を返す。

## Done when

- 指定scopeの事実または候補整理を、根拠つきで返せる。
- evidence不足、scope不一致、repo-local規約不足で続行できない場合は `blocked` を返す。
```

この雛形はrepo-local supplementで短く参照できるようにするための例である。詳細な共通契約は `subagent-orchestration` を正本とする。

## 禁止事項

- 共通skill側へ特定repoのagent名、model、人格、分類語を固定しない。
- prep scoutに修正、テスト実行、docs更新、review判定を担当させない。
- scout結果をMain Agentの採用判断なしに確定計画として扱わない。
- planning scout相当の分類結果を、raw requestから直接作った実装taskとして確定しない。
- scout未整備だけを理由に `wf-explore` をblockedにしない。
- repo調査なしでprep scoutの責務や呼び出し条件を決めない。

## 出力ルール

- まず既存のAGENTS、workflow map、repo-local skill、custom agent、work templateを整理する。
- 分離するprep scout候補と、分離しない範囲を一覧にする。
- 作成または更新するファイルを提案する。
- ユーザーが作成を求めている場合だけ、最小セットを作成する。
- Codexでファイルを作成または更新する場合は `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まない。

## 完了報告

最後に次を報告する。

- 調査した既存指示、agent、skill、template
- 作成または更新したファイル
- 追加したprep scoutの責務
- `wf-explore` からのrouting方法
- fallbackとblocked条件
- Main Agentが採用判断として残す項目
- 人間が判断する点
