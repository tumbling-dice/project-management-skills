# Reviewable Gateの作成手順

`docs/review/reviewable-gate.md` を作るときに使う。

## 目的

Reviewable Gateは、差分を人間レビューまたは独立レビューへ進めてよい条件を定義する。失敗中のテストや不明な検証がある差分は、レビュー可能ではなく作業途中として扱う。

`review-routing.md` は、どの種類の差分を誰が見るか、専門reviewや人間判断が必要かを分ける文書である。Reviewable Gateはレビュー開始条件、Review Routingはレビュー先と判断境界を扱う。

## 標準gate項目

- build、compile、または同等のPJ検証が成功している。
- 差分に対応するtestがある。testがない場合は理由が記録されている。
- 関連testが通っている。
- 通すためにtestを削除、skip、弱体化していない。
- commandとresultが記録されている。
- 未実行verificationが理由とrisk付きで記録されている。
- authentication、authorization、tenant、個人情報、secrets、loggingへの影響を確認している。
- 非対象範囲を変更していない。

## 例外扱い

既知の無関係な失敗がある場合は、次を必須にする:

- 失敗が今回差分と無関係である根拠
- ログまたはコマンド出力の要約
- 変更領域に関係するテスト結果
- 影響とrisk
- 例外としてreview開始する人間の承認

## ルール

- すべてのtaskで使える大きさに保つ。
- gateを完全なリリースチェックリストにしない。
- review可能状態と本番release判断を分ける。
- 認証、権限、PII、DB migration、release操作、外部serviceがあるPJでは、Reviewable Gateだけに詰め込まず `review-routing.md` を別に作る。
