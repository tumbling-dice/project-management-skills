# 作業文脈の作成手順

`docs/work/_template.md`、`docs/work/_template.state.json`、チケット雛形、レビュー説明雛形を作るときに使う。

## 標準形

作業文脈は、長いチャット履歴に依存せず作業を継続するための短命な入力である。同じ `task-id` のMarkdownとstate fileを1ペアにする。

```text
docs/work/<task-id>.md
docs/work/<task-id>.state.json
```

Markdownは人間が読む説明、判断、計画、レビュー観点を置く。state fileはworkflowが読む状態だけを置く。

state fileには方針、判断理由、調査メモ、長いメモを書かない。置けるものは次に限る。

- Markdownへの参照
- workflow statusと工程ごとの進捗
- 対象ファイル、関連ファイル
- 実行予定または実行したコマンドと結果
- 最終更新日

state fileだけで判断が必要になった場合は、対応するMarkdownを読む。Markdownとstate fileが矛盾する場合は、後続workflowへ進めず人間確認または作業コンテクスト更新へ戻す。

検証コマンドのsource of truthが別文書にあるPJでは、state fileの `commands` にはこのタスクで実行予定または実行したcommandと結果だけを記録し、候補一覧は `docs/contract/verification-commands.md` へ寄せる。

共通workflowの使い分けがPJ内で迷いやすい場合は、`docs/contract/workflow-map.md` を作り、作業文脈から次workflowへ渡す成果物を対応づける。

## 変更説明のセクション

- `概要`
- `背景`
- `変更内容`
- `非対象範囲`
- `テスト`
- `E2E影響`
- `検証`
- `リスク`
- `レビュー担当者へのメモ`

## ルール

- 長期的なPJ計画をrootの `TODO.md` に集約しない。
- 事実と仮説を分ける。
- verificationを実行した場合は、state fileに正確なcommandとresultを記録する。
- 未実行のcheckは、理由とriskを添えて記録する。
- workflow進捗、対象ファイル、関連ファイル、コマンドはstate fileへ反映する。
- state fileの `commands` は、`cmd`、`purpose`、`status`、`result` を持つobject配列にする。`status` は `planned`、`run_passed`、`run_failed`、`skipped` のいずれかを使う。
- state fileには方針、判断理由、調査メモ、secrets、顧客データ、本番ログを保存しない。
- 検証候補の一覧や権限要否は、作業文脈へ複製しすぎず `verification-commands.md` を参照する。
- UI変更では、対象画面、route、対象screen spec、再確認するUI文書だけを作業文脈へ残す。
- 作業文脈は短命な入力として扱う。完了後に残すべき内容は `docs/spec/` または `docs/contract/` へバックポートし、個別作業ファイルを長期文書として保守しない。
- 次workflowへのhandoffが必要な場合は、作業文脈内の要約か `handoff` を使い、長い会話履歴を前提にしない。
- secrets、顧客データ、本番ログを保存しない。
