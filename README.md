# Project Management Skills

このリポジトリは、AIコーディングエージェントが複数のプロジェクトで再利用する作業手順を管理します。利用者は、必要な資材を自分の環境へインストールし、目的に合うSkillを呼び出せます。

管理する資材は次の二種類です。

| 資材 | 内容 |
| --- | --- |
| Agent Skill | いつ使うか、何を根拠にするか、どこまで変更できるか、何を返すかを記述した指示書 |
| Codex custom agent | Skillから独立した役割へ作業を委譲するためのCodex設定。このリポジトリでは文書監査とテスト内容の確認を読み取り専用で担当する |

## インストールする

このリポジトリを、開発中のプロジェクトとは別の任意の場所へ `git clone` してください。`git clone` の完了後、この `README.md` があるディレクトリへ移動し、使用するOSに対応したコマンドを実行してください。配置内容だけを確認する場合はdry runを使ってください。dry runではディレクトリやファイルを作りません。

| OS | dry run | インストール |
| --- | --- | --- |
| Linux / macOS | `./scripts/install.sh --dry-run` | `./scripts/install.sh` |
| Windows PowerShell | `.\scripts\install.ps1 -DryRun` | `.\scripts\install.ps1` |

Skillは `~/.agents/skills` へ配置します。custom agentは、Codexの設定場所を示す `$CODEX_HOME` の `agents` ディレクトリへ配置します。`$CODEX_HOME` が未設定の場合は `~/.codex/agents` を使います。

| 対象 | Linux / macOS | Windows |
| --- | --- | --- |
| リポジトリ直下のSkillディレクトリ | `~/.agents/skills/<skill-name>` へのシンボリックリンク | `~/.agents/skills/<skill-name>` へのコピー |
| `agents/*.toml` | `$CODEX_HOME/agents` へのシンボリックリンク | `$CODEX_HOME/agents` へのコピー |
| 同名の配置先が存在する場合 | 既存の配置先を残す | 利用者が `y` または `yes` と答えた場合だけ上書き |

Linux / macOSでは、シンボリックリンクを通じてこのリポジトリの更新が配置先にも反映されます。Windowsではコピーを配置するため、更新を反映するにはインストールスクリプトを再実行します。

旧配置先の `~/.codex/skills` はインストールスクリプトの管理対象外です。

## Skillを呼び出す

Skill名を `$skill-name` の形式でプロンプトに書くと、そのSkillを明示的に呼び出せます。工程を進める `wf-*`、作業を引き継ぐ `handoff`、実装済みテストをレビューする `review-tests` は、ユーザーまたは上流のSkillが名前を明示した場合だけ使います。

それ以外のSkillは、依頼内容がSkillの利用条件と一致する場合に自動で選ばれることがあります。迷う場合は、一覧から目的に合うSkillを選び、名前を明示してください。

通常の実装は、調査と実装の間に人間承認を置きます。

```text
$wf-explore（調査と計画）
  -> 実装前レビュー
  -> 人間による計画承認
  -> $wf-implement（実装と後続工程）
     -> $wf-verify（検証）
     -> $audit-docs（文書監査）
     -> $wf-review（レビュー可能か判定）
        -> $review-tests（テストを変更した場合）
  -> 人間レビュー
```

`wf-explore` が作るのはレビュー対象の計画です。人間がその計画を承認するまで、`wf-implement` はコードやテストを変更しません。レビュー後の指摘は、必要に応じて `$wf-review-triage` が実装、再検証、再計画、追加調査、専門レビュー、人間判断へ振り分けます。

## 各プロジェクトで補う情報

このリポジトリのSkillは、工程の順序、承認の境界、工程間で渡す情報を定めます。対象プロジェクトによって異なる次の情報は、各プロジェクト側で定義します。

- 検証コマンドと、そのコマンドを実行する `test_runner`
- 専門レビューが必要になる条件と、その担当
- 操作に必要な権限と、安全のために自動化しない範囲

各プロジェクトは、これらを自身のSkill、custom agent、作業ルールへ記録します。`scaffold-agent-*` は、プロジェクトを調べて初期設定を作るためのSkillです。

## Skill一覧

### 工程

| Skill | 役割 |
| --- | --- |
| [`wf-explore`](wf-explore/) | コード変更前に既存実装と影響範囲を調べ、実装前レビューを経た計画と人間の判断事項を作る。 |
| [`wf-implement`](wf-implement/) | 人間が承認した計画の範囲で、実装、対応テスト、検証、文書監査、レビューを進める。 |
| [`wf-verify`](wf-verify/) | 対象プロジェクトの `test_runner` へ検証を委譲し、実行内容と結果を記録する。 |
| [`wf-review`](wf-review/) | 計画、変更差分、テスト、検証結果、文書、安全面の記録が揃っているか確認し、人間または専門レビューへ進めるか判定する。 |
| [`wf-review-triage`](wf-review-triage/) | レビュー指摘を次の担当と工程へ振り分ける。指摘対応の実装やレビュー再判定は行わない。 |

### 実装支援・文書・引き継ぎ

| Skill | 役割 |
| --- | --- |
| [`document-code-intent`](document-code-intent/) | 実装変更に合わせ、現在のコードとテストの責務、契約、前提、設計理由をコメントへ記録する。 |
| [`write-japanese-docs`](write-japanese-docs/) | 書き手と読み手の関係を固定し、根拠に沿った日本語文書を作成または改訂する。 |
| [`feedback-to-criteria`](feedback-to-criteria/) | ユーザーの訂正や差戻しを、今回の修正と再利用可能な判断基準へ分ける。 |
| [`idiot`](idiot/) | 調査結果や作業停止理由から、人間が答える必要のある判断だけを質問へ変える。 |
| [`handoff`](handoff/) | 作業根拠、実行結果、未確認事項、変更しない範囲、次の担当を引き継ぎ情報へまとめる。 |

### 導入・監査・移行

| Skill | 役割 |
| --- | --- |
| [`scaffold-project`](scaffold-project/) | 新規または文書が少ないプロジェクトへ、仕様の根拠、AIの作業ルール、作業記録、レビュー条件を作る。 |
| [`scaffold-agent-prep-scout`](scaffold-agent-prep-scout/) | `wf-explore` の前に読み取り専用で事実を集めるagentと、その委譲規則を作る。 |
| [`scaffold-agent-test-runner`](scaffold-agent-test-runner/) | 対象プロジェクトの検証コマンドを実行する `test_runner` と検証手順を作る。検証自体は実行しない。 |
| [`scaffold-agent-reviewer`](scaffold-agent-reviewer/) | 対象プロジェクトに必要な専門レビュー担当、実装前レビュー、レビュー可能条件、指摘の戻り先を作る。 |
| [`audit-docs`](audit-docs/) | プロジェクト文書、作業状態、実装差分、検証結果の不整合を監査し、内容が一意に決まる文書修正や長期文書への反映を行う。 |
| [`audit-repo-skill`](audit-repo-skill/) | プロジェクト内の `AGENTS.md`、Skill、custom agent、レビューの流れ、検証手順を監査する。 |
| [`audit-workflow`](audit-workflow/) | 分離した一時作業ディレクトリで `wf-*` を実行し、一連の工程を完了できるか検証する。 |
| [`migrate-workflow`](migrate-workflow/) | 既存プロジェクトの運用資産を共通工程へ移す対応表を作る。対象ファイルは変更しない。 |

### レビュー

| Skill | 役割 |
| --- | --- |
| [`review-tests`](review-tests/) | `wf-review` から渡された実装済みテストが、期待動作を正しく判定できるか、意味のある境界を扱うか、実行ごとに不安定にならないかを読み取り専用で確認する。 |

### サブエージェントへの委譲

| Skill | 役割 |
| --- | --- |
| [`subagent-orchestration`](subagent-orchestration/) | 作業全体を担当するMain Agentが、独立した範囲を別のagentへ委譲する契約を定める。 |
| [`subagent-execution`](subagent-execution/) | 委譲を受けたagentが担当範囲を広げず、成果と根拠、続行できない理由を返す契約を定める。 |

## Custom agent

`agents/` では、共通工程から呼び出すCodex custom agentを管理します。現在の二つのagentは読み取り専用で、ファイル修正や検証コマンドの実行を行いません。

| Agent | 呼出し元 | 役割 |
| --- | --- | --- |
| [`project_doc_auditor`](agents/project_doc_auditor.toml) | `audit-docs` | 文書と実装・検証記録の矛盾、古い前提、未決事項、長期文書へ反映する候補を監査する。 |
| [`test_reviewer`](agents/test_reviewer.toml) | `wf-review` / `review-tests` | 実装済みテストの判定内容、境界、不自然な弱体化、実行ごとの不安定さをレビューする。 |

## リポジトリを保守する

共通Skillはリポジトリ直下の `<skill-name>/` で管理します。各Skillには `SKILL.md` を置き、Skill一覧に表示する名前や既定プロンプトが必要な場合は `agents/openai.yaml` を追加します。共通custom agentは `agents/<agent-name>.toml` で管理します。

Skillを作成または更新したら、`SKILL.md` と `agents/openai.yaml` の内容が一致しているか確認します。次のコマンドは、Skill名と `SKILL.md` 冒頭にある `name`、`description` の形式を検証します。

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./<skill-name>
```

Skillの追加、役割変更、呼出し条件の変更では、このREADMEの一覧と工程説明も更新します。インストールスクリプトを変更した場合は、Linux / macOS向けの配置とdry runを次のテストで確認します。

```bash
bash tests/install_test.sh
```

## License

[MIT License](LICENSE)
