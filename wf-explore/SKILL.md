---
name: wf-explore
description: "`$wf-explore` が明示された場合だけ使う。コード変更前の調査、実装計画、pre-implementation review、開始可否、判断質問を一つの作業contextへまとめる。人間承認まで実装・テスト更新は行わない。"
---

# wf-explore

このskillは、実装前の調査と計画を分けず、1つの作業コンテクストで完了させるためのワークフローである。目的は、関連ファイル、既存実装、既存テスト、関連ドキュメント、影響範囲を確認したうえで、修正開始前に人間がレビューできる計画と、最後に答えるべき判断質問を同じ場所へ残すことである。

`prep_status: ready` は「人間レビューへ出せる」という意味である。コード変更を始めるには、人間が計画をレビューし、修正開始を明示承認する必要がある。

## 使わない場面

- 承認済み計画に沿って実装する段階。その場合は `wf-implement` を使う。
- 実装後の検証証跡を作る段階。その場合は `wf-verify` を使う。
- 差分がレビュー可能か判定する段階。その場合は `wf-review` を使う。
- 既存の長い成果物を次agentへ渡すpacketにするだけの場合。その場合は `handoff` を使う。

## 前提

このskillは、`$scaffold-project`、`$scaffold-agent-prep-scout`、`$scaffold-agent-reviewer` で整備された作業コンテクストtemplate、repo-local supplement、prep scout、pre-implementation review routingを使う。template、scout委譲契約、reviewer設計の詳細はこのskillへ複製しない。

出力先PJに必要なtemplateやroutingがない場合は、共通側で即席に設計せず、作業コンテクストに不足として記録し、該当するscaffold skillまたは人間判断へ戻す。

## 出力先

出力先はPJの慣習に従う。慣習がなければ、共有する作業コンテクストとして `docs/work/<task-id>.md` と `docs/work/<task-id>.state.json` の1ペアを推奨する。チケット管理がある場合は、チケット本文またはコメントに同じ内容を残してもかまわない。

`task-id` やファイル名が指定されていない場合は、依頼内容から短い kebab-case 名を付ける。命名だけで停止しない。既存ファイルと衝突する場合は上書きせず、別名にするかユーザーへ確認する。

Codexで作業コンテクストやstate fileを作成または更新する場合は、手作業のMarkdownやJSON作成にも `apply_patch` を使う。shellのheredoc、`cat > file`、`tee` などで本文を書き込まないこと。

ユーザーが会話上の提示だけを求めた場合だけ、ファイルを作らずに本文へ出力する。

## State File

`$scaffold-project` で作られる `docs/work/_template.md` と `docs/work/_template.state.json` があるPJでは、そのペア運用に従う。詳細な項目定義や `commands` の形は、PJ内のtemplateまたは `$scaffold-project` の `references/work/work-context.md` を参照し、このskillへ複製しない。

Markdownには人間が読む計画、判断理由、調査メモ、レビュー観点を残す。state fileにはMarkdownへの参照、workflow status、進捗、対象ファイル、関連ファイル、実行予定または実行したコマンドと結果だけを置く。方針、判断理由、調査メモ、secrets、顧客データ、本番ログはstate fileへ書かない。

Markdownとstate fileが矛盾する場合は `prep_status: ready` にしない。PJにstate file templateがない場合は、このworkflow中にschemaを再設計せず、`$scaffold-project` またはrepo-local supplement更新の候補として記録する。

## 手順

1. 依頼内容、期待動作、非対象範囲、制約を作業コンテクストへ記録する。
2. repo-local supplementを読み、template、prep scout、pre-implementation reviewer routing、検証・review条件を確認する。
3. supplementに従ってprep scoutを使う。使えない場合はMain Agentが同じ観点を読解で補い、補った内容と残る不足だけを記録する。
4. 関連するsource、tests、fixtures、設定、仕様根拠、作業契約を確認する。テスト実行は必須ではなく、実行した場合も調査上の観測結果として扱う。
5. 事実、仮説、未確認事項、文書不整合、影響範囲、risk notesを整理する。計画確定を止める不足と、実装中に確認できる事項を分ける。
6. 変更方針、変更予定ファイル、テスト方針、非対象範囲、修正開始条件を計画メモとして作る。実装後の検証コマンドはstate fileの `commands` に記録する。`blocked` 時は確定計画ではなく条件付き候補として書く。
7. 影響範囲からpre-implementation reviewerを選び、repo-local routingに従って計画メモを渡す。対応するreviewerやroutingがない場合は、未整備事項と戻り先を記録し、`prep_status: ready` にしない。
8. pre-implementation review結果を計画メモへ反映する。指摘をそのまま追加実装要求にせず、scope追加、仕様判断、risk acceptanceが必要なものは人間判断または追加の `wf-explore` へ戻す。
9. review反映後の計画メモをもとに、人間レビュー観点、人間が判断する点、修正開始可否 `ready` / `blocked` を出す。
10. 最後に、同じ作業コンテクストを入力として `$idiot` の出力形式で人間が答えるべき判断だけを整理する。確認事項がない場合は「質問はありません。」と返す。
11. ファイル出力する場合は、state fileのMarkdown参照、workflow status、進捗、対象ファイル、関連ファイル、`commands` を更新する。

## Decision Clarificationへの接続

最後の判断整理は、このskillの末尾で `$idiot` の出力形式として返す。ファイルへ残す場合は、同じ作業コンテクスト内に `Decision Clarification` セクションとして含める。ユーザーが独立した判断整理を求めた場合、または質問だけを別途人間に回す必要がある場合だけ、`$idiot` の独立成果物として切り出す。

質問化するもの:

- テスト期待値が決まらない事項。
- 変更予定ファイルや非対象範囲が変わる事項。
- 認証、認可、tenant、PII、secret、ログ、外部入力へのリスク受容。
- `prep_status: blocked` から `ready` へ進むために必要な判断。
- 専門reviewや追加調査へ回すか、人間がscopeから外すかを決める事項。
- pre-implementation reviewの `Plan concerns` のうち、scope、仕様、risk acceptanceを変える事項。

質問化しないもの:

- 実装開始を止めない補足リスク。
- 既存実装を読むだけで解消できる事実不足。
- すでに非対象範囲として明示された事項。
- このskillの既定動作で処理できる出力先、命名、テスト未実行。

## 作業コンテクストへの記録

出力先PJの作業コンテクストtemplateに従う。templateに該当欄がある場合はそこへ記録し、欄名が違う場合は同等の欄へ寄せる。template本体の不足を見つけた場合、このworkflow中に雛形を再設計せず、`$scaffold-project` またはrepo-local supplement更新の候補として記録する。

少なくとも次を後続の `wf-implement` が読める形で残す。

- 依頼、期待動作、非対象範囲、制約
- 確認したsource、tests、仕様根拠、作業契約
- prep scoutの利用有無と、Main Agentが採用した事実
- 事実、仮説、未確認事項、文書不整合
- 影響範囲、risk notes、非対象範囲を守る確認
- 変更方針、変更予定ファイル、テスト方針
- pre-implementation reviewの委譲先、結果、反映後の計画メモ
- 人間レビュー観点、人間が判断する点、修正開始可否、修正開始条件
- `Decision Clarification`

state fileを使うPJでは、少なくとも次を後続の `wf-implement` が読める形で残す。詳細schemaは `docs/work/_template.state.json` に従う。

- Markdownへの参照
- workflow statusと進捗
- 変更予定ファイル、関連ファイル
- 実装後に実行または委譲する検証コマンド

## 最後に返すDecision Clarification形式

```text
Q1. <質問>
A1.
- <選択肢>
- <選択肢>
推奨: <推奨初期値と理由>

Q2. <質問>
A2.
- <選択肢>
- <選択肢>
推奨: <推奨初期値と理由>
```

## 不明瞭点に含めない既定動作

次は既定動作が決まっているため、人間回答が必要な `不明瞭点` に含めない。

- `task-id`、成果物名、出力先が未指定の場合は、依頼内容から短い kebab-case 名を付け、PJ慣習または `docs/work/<task-id>.md` と `docs/work/<task-id>.state.json` を使う。
- 対象ディレクトリがgit repositoryでない場合は、その事実を記録し、git確認不能だけで停止しない。
- テスト実行が明示されていない場合は、既存テストを読解のみで扱い、テスト実行未実施と記録する。
- 最後の判断整理は、独立成果物を求められていない限り同じ作業コンテクスト内に含める。

## statusの扱い

- `ready`: 人間レビューへ出せる状態。pre-implementation reviewが完了し、その結果が計画メモへ反映済みであることを含む。人間の承認前に実装してはいけない。
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
- pre-implementation reviewの指摘を、そのまま追加実装要求として扱わない。
- pre-implementation reviewを、実装後の差分review、reviewable gate、検証証跡の代替として扱わない。

## 完了報告

最後に次を報告する。

- 作業コンテクストの出力先
- state fileの出力先
- `prep_status: ready` / `prep_status: blocked`
- 確認した主なファイル
- 確認した主なドキュメントと、文書不整合の扱い
- 事実、仮説、未確認事項の要約
- 変更予定ファイル
- テスト方針
- state fileに記録した検証コマンド
- pre-implementation reviewの委譲先、結果、計画メモへの反映状況
- 人間レビュー観点
- `Decision Clarification` の質問、または「質問はありません。」
- 修正開始には人間レビューと承認が必要であること
