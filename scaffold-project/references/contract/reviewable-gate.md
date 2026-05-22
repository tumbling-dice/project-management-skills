# Reviewable Gateの作成手順

`docs/contract/reviewable-gate.md` を作るときに使う。

## 目的

Reviewable Gateは、差分を人間レビューまたは独立レビューへ進めてよい条件を定義する。失敗中のテストや不明な検証がある差分は、レビュー可能ではなく作業途中として扱う。

`review-routing.md` は、どの種類の差分を誰が見るか、専門reviewや人間判断が必要かを分ける文書である。Reviewable Gateはレビュー開始条件、Review Routingはレビュー先と判断境界を扱う。

## 標準gate項目

- build、test、lint、typecheckなどrepoで必要な検証証跡がある。
- 差分に対応するtestがある。testがない場合は理由が記録されている。
- 通すためにtestを削除、skip、弱体化していない。
- 未実行verificationが理由とrisk付きで記録されている。
- auth、PII、secret、tenant、DB、外部service、release影響は `review-routing.md` に従って扱っている。

## 例外扱い

既知の無関係な失敗がある場合は、作業コンテクストMarkdownに根拠、影響、risk、人間承認を記録し、state fileの `commands` に実行結果を記録する。

## ルール

- すべてのtaskで使える大きさに保つ。
- gateを完全なリリースチェックリストにしない。
- review可能状態と本番release判断を分ける。
- 認証、権限、PII、DB migration、release操作、外部serviceがあるPJでは、Reviewable Gateだけに詰め込まず `review-routing.md` を別に作る。
