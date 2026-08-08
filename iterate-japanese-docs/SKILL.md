---
name: iterate-japanese-docs
description: "`$iterate-japanese-docs` が明示された場合だけ使う。`japanese_doc_reviewer` に日本語文書の全文レビューを委譲し、指摘を `$write-japanese-docs` で修正して再レビューする。単独レビュー、初稿作成、判断が必要な内容変更、ソースコード変更には使わない。"
---

# 日本語文書をレビューと修正で収束させる

対象文書の修正はMain Agent、執筆規範への適合判定はread-onlyの `japanese_doc_reviewer` が担当する。Main Agentがreviewを代行せず、各修正後に更新済み全文をfreshなreviewerへ渡す。

## 入力を固定する

開始前に次を確定する。

- 対象ファイルの正確なpath
- 元の依頼、変更範囲、形式、非対象範囲
- 書き手、読み手、目的、読後に求める判断または行動
- repo規則、直接参照される文書、本文で断定する事実の根拠
- 1以上のreview回数上限。ユーザー指定がなければ5回

対象ファイルを一意に特定できない場合は編集せず、`workflow_status: blocked` として必要な入力を返す。開始時の対象と制約は反復中に広げない。

## 全文レビューを委譲する

各回で新しい `japanese_doc_reviewer` sessionを起動し、`$subagent-orchestration` に従って次を渡す。

- `Agent`: `japanese_doc_reviewer`
- `Scope`: 対象ファイルの全文
- `Goal`: `$write-japanese-docs` の執筆規範への適合判定
- `Do not`: ファイル編集、修正文作成、対象外レビュー
- `Evidence`: 現在の対象ファイル、入力で固定した制約と根拠、現在のdiff
- `Deliver`: `result`、`review_status`、finding、missing evidence、未確認事項、reviewしなかった範囲
- `Done when`: 全対象の判定完了、またはreview不能な理由と必要な証拠の特定

前回のfindingを次のreviewerのauthorityにせず、更新後の文書と現在も有効な根拠だけを渡す。委譲後に対象ファイルが変わった場合は結果を採用せず、更新後の証拠で再レビューする。

`japanese_doc_reviewer` が利用できない場合はMain Agentが代行せず、`workflow_status: blocked` とする。

## 判定に応じて進める

review結果を次のように扱う。

- `result: blocked`: 安全なrepo内読取で補える証拠だけを追加して再レビューする。対象、意味、方針を決める必要がある場合は停止する。
- `review_status: pass`: 反復を終了する。
- `review_status: needs-revision`: findingごとに、根拠から修正内容が一意に決まるか確認する。
- 定義外の状態または必要項目が欠けた結果: 採用せず、reviewerへ証跡補完を戻す。補完できなければ停止する。

次をすべて満たすfindingだけを同じ反復内で修正する。

- 入力で固定した目的、対象、形式、非対象範囲を変えない
- repo規則と確認済みの根拠から、必要な内容が一意に決まる
- 不明な事実、因果、数値、固有名詞を新しく断定しない
- 対象ファイルの範囲内で解消できる

読み手、目的、仕様、事実、対象範囲の選択が必要なfindingは推測で直さず、人間判断または追加根拠が必要な項目として停止する。

修正可能なfindingと判断待ちのfindingが混在する場合は、修正可能なものだけを適用して全文を再レビューし、更新後も残る判断待ちを返す。判断待ちのfinding自体には手を加えない。

## 指摘を修正する

修正可能なfindingを `$write-japanese-docs` への入力として使い、対象ファイルの全文へ執筆規範を適用する。findingは修正条件であり、新しい事実の根拠として扱わない。

修正前に、上限内で修正後のreviewを少なくとも1回実行できることを確認する。現在のreviewで上限に達した場合は対象文書を変更せず、残findingと追加回数の必要性を返す。

元の書き手、読み手、目的、読後に求める判断または行動を維持する。対象外の既存差分を戻さず、review合格だけを目的とした情報削除、表現の機械的な均一化、対象外ファイルへの変更を行わない。

修正後は `$write-japanese-docs` が求める事実照合と文書検査を行い、再び全文レビューへ戻る。

## 反復を停止する

次のいずれかで停止する。

- reviewerが `review_status: pass` を返した
- reviewerが必要とする証拠を取得できない
- 修正に人間判断、scope拡張、外部書込み、破壊操作が必要
- 修正後も、同じ対象箇所、規範、修正条件のfindingが実質的に変わらず再発した
- 対象文書に差分を作れず、次のreview結果を変える根拠もない
- 指定したreview回数の上限に達した

上限到達や停滞を `pass` として扱わない。続行する場合は、残finding、新しい根拠、追加回数をユーザーに確認して新しい実行として始める。

## 結果を返す

経過を周回ごとに再掲せず、最終状態に必要な情報だけを返す。

```text
workflow_status: pass | blocked
review_iterations: <reviewした回数>
changed: <変更した対象ファイルと要約>
final_review: pass | needs-revision | not-reviewed
remaining: <残finding、missing evidence、人間判断。なければnone>
next: none | provide-evidence | human-decision | invoke-again
```

reviewerの詳細なfindingを同じ出力へ複製せず、残項目の位置、規範、修正条件だけを示す。

## 禁止事項

- このSkillを `$write-japanese-docs` の終了後に自動起動しない。
- reviewerを呼ばずに `workflow_status: pass` としない。
- reviewerのread-only境界を外し、同じagentへ修正を担当させない。
- 前回のreview結果を、更新後全文の再レビューとして流用しない。
- findingを消すためにテスト、検証、根拠、注意書きを削除または弱体化しない。
- reviewerの合否を文書内容の承認、公開、merge、release、risk acceptanceとして扱わない。
