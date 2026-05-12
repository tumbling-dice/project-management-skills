---
name: wf-explore
description: ユーザーが $wf-explore を明示した場合だけ使う。コード変更前に、調査、実装計画、修正開始可否、人間レビュー観点、最後の判断質問整理を単一の作業コンテクストで行う。人間がレビューして承認するまで実装やテスト更新を始めない。
---

# wf-explore

このskillは、実装前の調査と計画を分けず、1つの作業コンテクストで完了させるためのワークフローである。目的は、関連ファイル、既存実装、既存テスト、関連ドキュメント、影響範囲を確認したうえで、修正開始前に人間がレビューできる計画と、最後に答えるべき判断質問を同じ場所へ残すことである。

`prep_status: ready` は「人間レビューへ出せる」という意味である。コード変更を始めるには、人間が計画をレビューし、修正開始を明示承認する必要がある。

## 使う場面

- 実装前に原因、影響範囲、既存パターン、既存テスト、関連ドキュメントを調べたい。
- 調査から実装計画まで、1回の依頼で進めたい。
- 修正開始前に、変更予定ファイル、テスト方針、検証コマンド、リスク、人間レビュー観点を整理したい。
- 最後に、同じ作業コンテクストを入力として `$idiot` の出力形式で確認事項を返したい。
- 非自明なコード変更、権限、PII、tenant、DB、E2Eに関わる変更の前に品質ゲートを置きたい。

## 使わない場面

- 承認済み計画に沿って実装する段階。その場合は `wf-implement` を使う。
- 実装後の検証証跡を作る段階。その場合は `wf-verify` を使う。
- 差分がレビュー可能か判定する段階。その場合は `wf-review` を使う。
- 既存の長い成果物を次agentへ渡すpacketにするだけの場合。その場合は `handoff` を使う。

## Template Source Rule

このskillは作業メモtemplateを所有しない。

1. 出力先PJに既存templateがある場合は、それをsource of truthとして使う。
2. PJ内templateがない場合だけ、`$scaffold-project` の `assets/templates/work-context.md` をfallbackとして構造参照する。fallbackはsource of truthの代替であり、全文を機械的に複製する必要はない。
3. fallbackも使えない場合だけ、下記「必須セクション」を最小構造として使う。

探す候補path:

- `docs/work/_template.md`
- `docs/work/template.md`
- `docs/templates/work-context.md`
- `docs/templates/implementation-plan.md`
- `.codex/templates/work-context.md`
- `.codex/templates/implementation-plan.md`
- `.codex/skills/*/assets/templates/work-context.md`

template構造を変更したい場合は、出力先PJのtemplate、または `scaffold-project` のtemplateを更新する。このskill内に同じ雛形を複製しない。

## 出力先

出力先はPJの慣習に従う。慣習がなければ、共有する作業コンテクストとして `docs/work/<task-id>.md` を推奨する。チケット管理がある場合は、チケット本文またはコメントに同じ内容を残してもかまわない。

`task-id` やファイル名が指定されていない場合は、依頼内容から短い kebab-case 名を付ける。命名だけで停止しない。既存ファイルと衝突する場合は上書きせず、別名にするかユーザーへ確認する。

Codexで作業コンテクストをファイルへ作成または更新する場合は、手作業のMarkdown作成にも `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まないこと。

ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力する。

## 手順

1. 依頼内容、目的、期待動作、非対象範囲、制約を整理する。
2. ユーザーが示したファイルはヒントとして扱い、明示的な変更禁止がない限り周辺を探索する。
3. repo-local supplementを確認する。
   - 候補は `AGENTS.md`、`.codex/skills/`、`.codex/agents/`、`docs/ai/`、`docs/review/`、`docs/verification/`、`docs/work/_template.md`、repo固有のworkflow mapである。
   - supplementが、実装前調査用のread-only補助agentやplanning補助agentを指定している場合は、そのagentへ委譲するか、使わない理由を作業コンテクストに記録する。
   - read-only prep scout は、観測事実を整理する context scout 相当と、要件、既存文書、作業候補、保留点を整理する planning scout 相当を指す。具体的なagent名、人格、model、分類語はrepo-local supplement側で決める。
   - 委譲する場合は `subagent-orchestration` の Delegation Packet に従う。補助agentには、実装、test実行、docs更新、採用判断、計画確定、次担当決定をさせない。
   - `prep補助agentの使用有無` には、使用したagent名またはrole category、結果状態 `done` / `blocked`、渡した主なevidence、返された事実や分類の要約、Main Agentが採用したevidenceと採用しなかったevidenceを記録する。
   - 補助agentが使えない場合でも、Main Agentは同じ観点を読解で補い、未使用理由、補った確認内容、残る不足を分けて記録する。
   - 補助agentが未整備、起動不能、scope不一致であることだけでは `prep_status: blocked` にしない。Main Agentの読解補完後も計画確定に必要な事実、scope、risk、文書根拠が足りない場合だけ `blocked` とする。
4. 関連ファイル、既存実装パターン、既存テストを確認する。
   - 既存テストの確認は、原則としてテストコード、fixture、設定、CI上の扱いを読むことである。
   - テスト実行は必須ではない。ユーザー依頼、repo手順、または原因切り分け上の必要性があり、破壊的でない場合だけ実行する。
   - テスト実行が明示されていない場合は、実行せず「既存テストは読解のみ。テスト実行は未実施」と記録する。
   - テストを実行した場合も、実装後検証ではなく調査上の観測結果として扱う。
5. 関連ドキュメントを確認する。
   - 候補は `README.md`、`AGENTS.md`、`docs/project/`、`docs/ai/`、`docs/review/`、`docs/verification/`、`docs/work/`、repo固有docsである。
   - 仕様、要件、設計、検証手順、review条件、AI利用ルールが関係する場合は、根拠にした節を記録する。
   - 文書と実態が食い違う場合は、文書不整合候補として記録する。
6. 影響範囲を分類する。
   - API
   - UI
   - DB / migration
   - 権限 / 認証 / 認可
   - tenant
   - PII / secret / ログ
   - 外部入力
   - E2E / smoke test
   - project docs / AGENTS / verification docs
7. `事実`、`仮説`、`未確認事項` を分ける。
8. 未確認事項が計画確定や修正開始可否を止めるか分類する。
9. 変更方針、変更予定ファイル、テスト方針、検証コマンドを作る。
   - `prep_status: blocked` の場合も、未確認事項の解消後に採りうる変更候補、変更予定ファイル候補、テスト候補を整理する。
   - blocked時の候補は確定計画ではない。`要確認`、`条件付き候補`、`人間判断後に確定` のように明示す。
   - 変更予定ファイルは、確定対象と条件付き候補を分けて書く。
   - 検証コマンドは、実装後に実行する候補として記載する。計画作成中には原則実行しない。
10. ドキュメント不整合の扱いを決める。
   - 期待動作や修正scopeに影響する不整合は `prep_status: blocked` とし、人間判断、文書更新、または追加調査へ戻す。
   - 不整合がない場合、または今回の修正判断に影響しない場合は、その理由を残す。
11. 認証、認可、tenant、PII、secret、ログ、外部入力、DB、E2E影響を確認する。
12. 人間レビュー観点と、人間が判断する点を明記する。
13. 修正開始可否を `ready` / `blocked` で出す。
14. 最後のフローとして、同じ作業コンテクストを入力に `$idiot` の手順と出力形式で人間が答えるべき判断だけを整理する。確認事項がない場合は質問数0として報告する。

## Decision Clarificationへの接続

最後の判断整理は、このskillの末尾で `$idiot` の出力形式として返す。ファイルへ残す場合は、同じ作業コンテクスト内に `Decision Clarification` セクションとして含める。ユーザーが独立した判断整理を求めた場合、または質問だけを別途人間に回す必要がある場合だけ、`$idiot` の独立成果物として切り出す。

質問化するもの:

- テスト期待値が決まらない事項。
- 変更予定ファイルや非対象範囲が変わる事項。
- 認証、認可、tenant、PII、secret、ログ、外部入力へのリスク受容。
- `prep_status: blocked` から `ready` へ進むために必要な判断。
- 専門reviewや追加調査へ回すか、人間がscopeから外すかを決める事項。

質問化しないもの:

- 実装開始を止めない補足リスク。
- 既存実装を読むだけで解消できる事実不足。
- すでに非対象範囲として明示された事項。
- このskillの既定動作で処理できる出力先、命名、template有無、テスト未実行。

## 必須セクション

既存templateに不足がある場合、作業コンテクスト側に次のセクションを追加する。template本体は勝手に変更しない。

- `調査目的`
- `依頼内容`
- `期待動作`
- `非対象範囲`
- `制約`
- `調査対象`
- `関連ファイル`
- `関連ドキュメント`
- `repo-local supplement`
- `prep補助agentの使用有無`
- `既存実装パターン`
- `既存テスト`
- `影響範囲`
- `ドキュメント根拠`
- `ドキュメント不整合と扱い`
- `事実`
- `仮説`
- `未確認事項`
- `変更方針`
- `変更予定ファイル`
- `テスト方針`
- `検証コマンド`
- `非対象範囲を守る確認`
- `リスク`
- `人間レビュー観点`
- `人間が判断する点`
- `Decision Clarification`
- `修正開始可否`
- `修正開始条件`

## 最後に返すDecision Clarification形式

```md
## Decision Clarification

clarification_status: ready_for_plan / ready_for_review / blocked

### Blocking Decisions

- decision:
  why blocking:
  options:
    - option:
      effect:
  recommended default:
  if deferred:
  updates:

### Non-blocking Risks

- risk:
  review note:

### Confirmed Inputs

- なし / あり

### Remaining Unknowns

- blocking:
- non-blocking:

### Next Step

- wf-implement / wf-explore / human decision / specialist review
```

## 不明瞭点に含めない既定動作

次は既定動作が決まっているため、人間回答が必要な `不明瞭点` や完了報告の迷った点に含めない。

- `task-id`、成果物名、出力先が未指定の場合は、依頼内容から短い kebab-case 名を付け、PJ慣習または `docs/work/<task-id>.md` を使う。
- PJ内templateがない場合は、fallback構造または必須セクションで作業コンテクストを作る。
- 対象ディレクトリがgit repositoryでない場合は、その事実を一度記録し、git確認不能だけで停止しない。
- テスト実行が明示されていない場合は、既存テストを読解のみで扱い、テスト実行未実施と記録する。
- 最後の判断整理は、独立成果物を求められていない限り同じ作業コンテクスト内に含める。

## statusの扱い

- `ready`: 人間レビューへ出せる状態。人間の承認前に実装してはいけない。
- `blocked`: 調査不足、未決事項、危険な前提、検証不能などにより計画を確定できない状態。

`ready` とする場合でも、承認済み計画ではなく「レビュー対象の計画」として扱う。

## 禁止事項

- 調査や計画中にコード修正、テスト更新、フォーマット変更を始めない。
- 未確認事項を確定事項として扱わない。
- 調査されていないファイルや挙動を確定事項として扱わない。
- 非対象範囲を計画に混ぜない。
- テスト削除、skip、assertion弱体化を前提にした計画を作らない。
- 認証、認可、tenant、PII、secret、ログ、外部入力への影響を未確認のまま安全扱いしない。
- secrets、credential、本番DB接続情報、マスキングしていない顧客データ、本番ログの生データを成果物へ含めない。
- 人間の代わりに仕様、security、privacy、release、risk acceptanceを確定しない。
- read-only補助agentの結果を、Main Agentの採用判断なしに確定計画として扱わない。
- planning補助agentがraw complaintを直接実装taskへ変換した結果を、そのまま確定計画にしない。
- repo-local supplementで定めたscopeを越える広い探索を、補助agentへの暗黙前提にしない。

## 完了報告

最後に次を報告する。

- 作業コンテクストの出力先
- `prep_status: ready` / `prep_status: blocked`
- 確認した主なファイル
- 確認した主なドキュメントと、文書不整合の扱い
- 事実、仮説、未確認事項の要約
- 変更予定ファイル
- テスト方針
- 検証コマンド
- 人間レビュー観点
- `Decision Clarification` の `clarification_status`
- 人間が答えるべき質問数
- 修正開始には人間レビューと承認が必要であること
