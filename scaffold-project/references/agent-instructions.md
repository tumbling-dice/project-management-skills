# Agent Instructionsの作成手順

`AGENTS.md` を作成・更新するときに使う。

## 目的

このファイルは、`AGENTS.md`をrepoで作業するAIエージェントが常に参照する短い指示セットにする。`AGENTS.md`は長いPJマニュアルや作業ログにしてはならない。

## 必須セクション

- `PJ概要`
- `標準動作`
- `実装ルール`
- `セキュリティルール`
- `Reviewable Gate`
- `コマンド`
- `一時的な作業文脈`
- `Git / worktree`
- `このファイルの更新方法`

## ルール

- 短く保つ。
- 一回限りの作業コンテクストを入れない。
- secrets、顧客詳細、本番credentialを入れない。
- 調査、計画、実装、検証、レビュー、triage、scaffold、audit などの作業依頼では、ユーザーまたは上流成果物が明示した `$skill-name` を使う、と書く。
- 個別workflow skillを通常依頼から選ぶ場合は、依頼内容とskillの目的が直接一致する場合だけにする、と書く。
- 仕様根拠と作業契約の整合auditは `project_doc_auditor` custom agentへ委譲し、Main Agentは `audit-docs` を自分で実行しない、と書く。
- `audit-docs` は短命な作業コンテクストMarkdownやstate fileを最新化し続けるのではなく、必要な内容を `docs/spec/` または `docs/contract/` へバックポートする、と書く。
- 検証はrepo内にscaffoldされた `test_runner` custom agentへ委譲し、Main Agentは `wf-verify` や検証コマンドを直接実行しない、と書く。
- formatterやformat checkは、repo手順でMain Agent担当とする場合だけ例外として実行し、その結果を検証証跡へ渡す、と書く。
- reviewable gateはrepo-local supplementで定義された実装を使い、custom agent委譲かgate summary方式かを明記する、と書く。
- reviewable gate実装が未整備の場合は停止して人間に不足を報告する、と書く。
- ユーザーが示したファイルは、明示的に変更対象限定とされない限りヒントとして扱う、と書く。
- 非自明な実装の前に探索と計画を要求する。
- レビュー前にテストと検証結果を要求する。
- 長い手順は埋め込まず、skillsやdocsへ誘導する。
