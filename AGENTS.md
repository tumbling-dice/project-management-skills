# AGENTS.md

このrepoは、`~/.agents/skills` で使う共通skillをGit管理するための管理ディレクトリである。

## PJ概要

- 共通skill本体は、このrepo直下の各skillディレクトリで管理する。
- Linux / macOS では、`~/.agents/skills` 側にこのrepo内skillディレクトリへのシンボリックリンクを置く。
- Windows では、`~/.agents/skills` 側にこのrepo内skillディレクトリをコピーする。既存pathがある場合は確認を取り、OKの場合だけ上書きする。
- 共通custom agent定義は、このrepo内の `agents/` で管理する。
- Linux / macOS では、`~/.codex/agents` 側にこのrepo内agent定義ファイルへのシンボリックリンクを置く。
- Windows では、`~/.codex/agents` 側にこのrepo内agent定義ファイルをコピーする。既存pathがある場合は確認を取り、OKの場合だけ上書きする。
- `.system` はこのrepoの通常管理対象外として扱う。

## 標準動作

- 新しいskillを作成したら、このrepo直下に `skill-name/` を作る。
- 新しいskillには、最低限 `SKILL.md` を置く。
- 既存skillの形式に合わせ、必要なら `agents/openai.yaml` も置く。
- 新しいskillを作成したら、install scriptで利用者環境へ配置できるようにする。
- 新しい共通custom agentを作成したら、このrepo内の `agents/<agent-name>.toml` で管理し、install scriptで利用者環境へ配置できるようにする。
- skillを作成または更新したら、`README.md` のskill一覧、routing policy、ユースケース、役割境界に影響がないか確認し、必要な更新を同じ作業内で行う。
- 既に同名pathがある場合は、上書きせず状態を確認してから進める。

## 実装ルール

- skill本文は簡潔にし、共通workflow、入力、禁止事項、出力形式を中心に書く。
- descriptionは主要なtriggerと非対象範囲を先頭側に置き、表示時に短縮されてもroutingできる長さにする。
- promptやagent指示は、結果、必要なcontext、変更してはいけない境界、承認が必要な操作、成功条件、出力を明記する。手順自体が要件でない限り、細かな進め方を固定しない。
- 同じ指示、trigger、承認条件を複数箇所で繰り返さない。安全なrepo内の読取、対象内編集、非破壊検証は止めず、外部書込み、破壊操作、費用発生、scopeの実質的拡張だけを確認対象にする。
- 「短く」「簡潔に」だけで出力量を制御しない。結論、根拠、重要な留保、次の操作など残す情報と、省く背景や反復を指定する。
- subagentを使う場合は、独立したscope、write ownership、戻り値、停止条件を定義する。並列化は独立して実行できる作業に限る。
- repo固有のコマンド、reviewer、test runnerの詳細は、共通skillではなく各repo内skillやcustom agentへ閉じ込める。
- 共通skill内で同じtemplateを複製しない。templateのsource of truthを決めて参照する。
- 配布前提のため、skill内に `/home/...`、`/tmp/...`、個人環境のcheckout先などのローカルフルパスを書かない。別skillの資材は `$skill-name` と `assets/...`、`references/...`、`scripts/...` のようにskill名と相対的なasset名で参照する。
- 新規skillや大きな更新では、`skill-creator` の考え方に従い、`SKILL.md` と `agents/openai.yaml` の整合を確認する。

## セキュリティルール

- secrets、credential、本番DB接続情報、本番ログの生データをskillや文書に含めない。
- 認証、認可、tenant、PII、secret、ログ、外部入力を扱うskillでは、確認観点と人間判断の戻り先を明記する。

## Reviewable Gate

- skill作成または更新後は、可能なら `quick_validate.py` で対象skillを検証する。
- skill作成または更新後は、`README.md` が現在のskill構成とworkflow routingを説明できているか確認する。
- workflow変更では、関連する上流skillと下流skillの役割境界を確認する。
- 実装系workflowは、テスト削除、skip、assertion弱体化、未実行検証の実行済み扱いを禁止事項に含める。

## コマンド

- skill検証:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./<skill-name>
```

- Linux / macOS install:

```bash
./scripts/install.sh
```

- Windows install:

```powershell
.\scripts\install.ps1
```

## 一時的な作業文脈

- 既存差分を勝手に戻さない。
- 作業対象外のskillは、必要な確認以外では変更しない。

## Git / worktree

- コミットはユーザーが明示した場合だけ行う。
