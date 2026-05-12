# エージェント指示

## PJ概要

要確認

AIエージェントは、既存コード、テスト、ドキュメントを確認してから変更する。

## 標準動作

- 調査、計画、実装、検証、レビュー、triage、scaffold、audit など作業を進める依頼では、最初に `workflow_router` custom agent へ委譲して次に使うworkflowを判定する
- Main Agentは `workflow-router` を自分で実行しない。`workflow_router` custom agent が使えない場合は停止し、人間に不足を報告する
- `workflow-router` が選んだworkflow skill、またはユーザーが明示した `$skill-name` だけを使う
- 個別workflow skillを、通常依頼から直接選ばない
- `workflow-router` はrouting結果だけを会話で返し、ファイル作成、ファイル更新、実装、検証、レビュー判定を行わない
- PJ文書群の整合auditは `project_doc_auditor` custom agent へ委譲する。Main Agentは `project-doc-consistency-audit` を自分で実行しない
- `project_doc_auditor` custom agent が使えない場合は停止し、人間に不足を報告する
- 検証はrepo内にscaffoldされた `test_runner` custom agentへ委譲する。Main Agentは `verification-workflow` や検証コマンドを直接実行しない
- formatterやformat checkは、repo手順でMain Agent担当とする場合だけ例外として実行し、その結果を検証証跡へ渡す
- `test_runner` custom agent が使えない場合は停止し、人間に不足を報告する
- reviewable gateはrepo-local supplementで定義された実装を使う。custom agentへ委譲する方式、または専門reviewer結果とgate文書を照合するgate summary方式のどちらかを明記する
- reviewable gate実装が未整備の場合は停止し、人間に不足を報告する
- 依頼が粗い場合、目的、背景、期待動作、制約を整理する
- 非自明な変更では、いきなり実装せず探索と計画を先に出す
- ユーザーが示したファイルはヒントとして扱う
- 「このファイル以外は変更禁止」と明示された場合のみ厳密な制約とする
- 事実、仮説、未確認事項を分けて報告する

## 実装ルール

- 既存実装パターンを優先する
- 新しい外部ライブラリを勝手に追加しない
- テストを削除または弱体化して通さない
- 認証、認可、権限チェックを弱めない
- 個人情報、token、secretをログに出さない

## セキュリティルール

- APIキー、パスワード、秘密鍵、token、本番DB接続情報を扱わない
- マスキングしていない顧客情報や本番ログを扱わない
- 本番デプロイ、本番DB操作、顧客通知、リリース判断は人間が行う

## Reviewable Gate

レビュー依頼前に以下を満たすこと。

- 変更に対応するテストを追加または更新している
- 関連テストを実行している
- build / lint / typecheck 相当の検証を実行している
- 実行したコマンドと結果を報告している
- 未実行の検証がある場合、理由とリスクを報告している
- repo-local supplementで必須とされた専門reviewとgate条件を確認している

テストが失敗している差分はレビュー対象ではなく作業途中である。

## コマンド

- 要確認

## 一時的な作業文脈

非自明な作業では、チケット、作業メモ、Draft PR相当の場所に作業文脈を残す。

rootのTODO.mdに長期的な作業文脈を集約しない。

## Git / worktree

- 1作業=1 branchを原則にする
- 複数AIで同じ作業ツリーを同時編集しない
- 作業開始時に git status と現在のbranchを確認する

## このファイルの更新方法

同じ注意を繰り返した時、またはレビューで同じ指摘が繰り返された時に、短いルールだけ追加する。
