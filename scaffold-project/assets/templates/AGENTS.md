# エージェント指示

## PJ概要

要確認

AIエージェントは、既存コード、テスト、ドキュメントを確認してから変更する。

## 文書分類

- `docs/spec/`: 仕様根拠。PJ目的、要件、architecture、画面責務、判断ログ。
- `docs/contract/`: 作業契約。AI利用ルール、検証コマンド、review条件、安全境界。
- `docs/work/`: 短命な作業コンテクスト。`<task-id>.md` と `<task-id>.state.json` を1ペアで扱い、完了後は必要な内容だけ `docs/spec/` または `docs/contract/` へ移す。

## 標準動作

- ユーザーまたは上流成果物が明示した `$skill-name` を使う。
- 非自明な変更では、いきなり実装せず `wf-explore` で作業コンテクストを作る。
- 仕様根拠と作業契約の整合auditは `project_doc_auditor` custom agentへ委譲する。
- 検証はrepo内 `test_runner` custom agentへ委譲する。formatterやformat checkはrepo手順でMain Agent担当の場合だけ実行する。
- reviewable gateはrepo-local supplementで定義された実装を使う。
- 依頼が粗い場合、目的、背景、期待動作、制約を整理する
- 事実、仮説、未確認事項を分けて報告する

## 禁止事項

- secrets、credential、本番DB接続情報、マスキングしていない顧客データ、本番ログの生データを扱わない。
- 本番デプロイ、本番DB操作、顧客通知、merge、release、risk acceptanceを承認しない。
- テスト削除、skip、assertion弱体化で通さない。
- 認証、認可、tenant、PII、secret、ログの扱いを未確認のまま安全扱いしない。

## コマンド

検証コマンド、review条件、workflow例外は `docs/contract/` を参照する。

## 一時的な作業文脈

非自明な作業では、チケット、作業コンテクスト、Draft PR相当の場所に作業文脈を残す。rootのTODO.mdへ長期集約しない。

## このファイルの更新方法

同じ注意を繰り返した時だけ短いルールを追加する。長い運用ルール、検証コマンド、review routing、安全境界は `docs/contract/` へ置く。
