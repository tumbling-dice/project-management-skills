---
name: idiot
description: ユーザーが自然文で、既存の調査結果、実装計画、review結果、blocked理由、未確認事項、人間判断待ちを、次へ進むための少数の判断質問へ整理したいと頼んだ場合に使う。$idiot の明示でも使う。仕様決定、実装、レビュー判定、検証実行は行わない。単なる仕様相談、要件整理、実装依頼には使わない。
---

# idiot

このskillは、調査結果、実装計画、review gate結果に含まれる未確認事項や `blocked` 理由を、人間が短時間で答えられる判断質問へ変換するためのワークフローである。目的は、長い計画や指摘を人間に丸ごと読ませるのではなく、実装やレビューを止めている判断だけを絞り込むことである。

## 使う場面

- `wf-explore` の作業コンテクストに、人間判断待ちや未確認事項が残っている。
- `wf-explore` が `prep_status: blocked` を返した。
- `wf-review` が `blocked` または `needs-specialist-review` を返し、人間判断、risk acceptance、再計画、専門review routingが必要になった。
- 未確認事項の一覧が長く、人間がどれに答えれば次へ進めるか分かりにくい。
- 計画やreview結果を再実行する前に、確定事項、非対象範囲、次workflowへ渡す入力を整理したい。

## 使わない場面

- AIが人間の代わりに仕様、リスク受容、release、security判断を確定する場合。
- コード修正、テスト更新、検証実行、review判定を行う場合。
- すでに承認済み計画があり、実装に進むだけの場合。
- 未確認事項が実装やreviewを止めていない場合。その場合は元workflowの `リスク` や `未確認事項` に残す。

## 入力

原則として、次のいずれかを入力にする。

- `wf-explore` の作業コンテクスト
- `wf-explore` の `prep_status: blocked` な計画
- `wf-review` の `blocked` / `needs-specialist-review` 結果
- チケット本文、作業メモ、review commentに残された人間判断待ち

入力が不足して何を質問すべきか判断できない場合は、質問を作らず `clarification_status: blocked` とし、不足している入力を列挙する。

## 手順

1. 入力から目的、期待動作、非対象範囲、制約を確認する。
2. `未確認事項`、`リスク`、`人間が判断する点`、`blocked理由`、`needs-specialist-review` 理由を抽出する。
3. 抽出した項目を分類する。
   - 実装開始、計画確定、review通過を止めている判断
   - 止めてはいないが人間レビューで見るべきリスク
   - 追加調査が必要な事実不足
   - 専門reviewやrepo内skillへroutingすべき事項
4. 実行を止めている判断だけを質問化する。
   - 質問は原則3〜5個以内に絞る。
   - すべての未確認事項を質問にしない。
   - 1つの質問で複数の実装条件やテスト期待値が決まるようにまとめる。
5. 各質問に、選択肢、推奨初期値、保留時の扱いを付ける。
6. 回答後に次workflowへ渡す情報を整理する。

## 質問の形式

各質問には次を含める。

- `decision`: 何を決める質問か。
- `why blocking`: なぜ次へ進めないか。
- `options`: 人間が選べる選択肢。原則2〜4個に絞る。
- `recommended default`: 既存実装、安全側、変更範囲の小ささ、ユーザー報告との整合のどれを根拠にした推奨初期値か。
- `if deferred`: 保留した場合の扱い。実装不可、review不可、再調査、非対象化、条件付き計画など。
- `updates`: 回答された場合に更新する確定事項、非対象範囲、計画入力、review routing。

`recommended default` は人間の代わりに仕様決定するものではない。判断材料として示し、最終判断は人間へ戻す。

## 質問を絞る基準

優先して質問にするもの:

- テスト期待値が決まらない事項。
- 変更予定ファイルや非対象範囲が変わる事項。
- 認証、認可、tenant、PII、secret、ログ、外部入力へのリスク受容。
- `blocked` から `ready` / `pass` へ進むために必要な判断。
- 専門reviewや追加調査へ回すか、人間がscopeから外すかを決める事項。

質問にしないもの:

- 実装開始を止めない補足リスク。
- 既存実装を読むだけで解消できる事実不足。
- すでに非対象範囲として明示された事項。
- 元workflowの出力形式、ファイル名、template有無など、既定動作で処理できる事項。

## 回答後の扱い

人間の回答が得られたら、次を整理する。

- `確定事項`: 回答により決まった仕様、scope、リスク受容。
- `非対象範囲`: 今回扱わないと決まった事項。
- `残る未確認事項`: まだ止めているものと、止めないがreviewで見るものを分ける。
- `次workflowへ渡す入力`: `wf-explore`、`wf-review`、専門review、human decision など。

未回答の質問は確定事項として扱いない。保留された場合は `if deferred` に従って戻り先を示す。

## 出力形式

```md
# Decision Clarification

## Status

clarification_status: ready_for_plan / ready_for_review / blocked

## Source

- input:
- current status:
- next workflow:

## Blocking Decisions

- decision:
  why blocking:
  options:
    - option:
      effect:
  recommended default:
  if deferred:
  updates:

## Non-blocking Risks

- risk:
  review note:

## Confirmed Inputs

- なし / あり

## Remaining Unknowns

- blocking:
- non-blocking:

## Next Step

- wf-explore / wf-review / specialist review / human decision
```

## 禁止事項

- 人間の代わりに仕様、security、privacy、release、risk acceptanceを確定しない。
- 未回答の質問を確定事項として扱わない。
- 質問を大量に並べて人間へ丸投げしない。
- 実装、テスト更新、検証実行、review判定を始めない。
- 元workflowの既定動作で処理できる事項を、人間判断待ちとして膨らませない。

## 完了報告

最後に次を報告する。

- `clarification_status`
- 人間が答えるべき質問数
- 次workflowへ渡す入力
- 保留時の戻り先
