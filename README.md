# Project Management Skills

AI coding agent を使うプロジェクトで、調査から引き継ぎまでの作業を分担するための共通 skill 集です。

このリポジトリは、複数のプロジェクトで再利用する skill と custom agent を Git で管理するものです。プロジェクト固有のコマンドや reviewer の設定は、各リポジトリの skill や文書で管理することを前提としています。

## インストール

リポジトリのルートで、使用する OS に対応したコマンドを実行します。

Linux / macOS:

```bash
./scripts/install.sh
```

Windows PowerShell:

```powershell
.\scripts\install.ps1
```

インストール前に対象だけを確認する場合は、dry run を使います。dry run はファイルを配置しません。

```bash
./scripts/install.sh --dry-run
```

```powershell
.\scripts\install.ps1 -DryRun
```

配置先と既存ファイルの扱いは OS によって異なります。

| 対象 | Linux / macOS | Windows |
| --- | --- | --- |
| repo 直下の `SKILL.md` を持つディレクトリ | `~/.agents/skills/<skill-name>` への symlink | `~/.agents/skills/<skill-name>` への copy |
| `agents/*.toml` | `$CODEX_HOME/agents` への symlink。`CODEX_HOME` が未設定なら `~/.codex/agents` | `$CODEX_HOME/agents` への copy。`CODEX_HOME` が未設定なら `~/.codex/agents` |
| 配置先に同名 path がある場合 | 既存 path を残して skip | 確認を表示し、`y` または `yes` と答えた場合だけ上書き |

旧配置先の `~/.codex/skills` は install script の管理対象外です。重複する skill がある場合は、`~/.agents/skills` への配置を確認してから、旧 path を利用者が整理してください。

## Skill の選び方

工程を進める `wf-*` skill は、ユーザーまたは上流の成果物が名前を明示した場合に使います。たとえば、実装前の調査を始める依頼では `$wf-explore` と指定します。自然文から工程 workflow を推測すると、人間承認や検証の境界が変わるためです。

補助や文書作成を担う skill は、依頼内容がその役割に直接一致する場合に限り、自然文からも使えます。コードのコメントへ責務や設計理由を残す場合は `document-code-intent` を使います。読みやすい日本語への改訂には `write-japanese-docs` を使い、既存の blocked 理由を判断質問へ直す場合には `idiot` を使います。

目的から選ぶ場合は、次の表を起点にしてください。

| 目的 | 最初に使う skill |
| --- | --- |
| 実装前に事実、影響範囲、計画、判断事項を整理する | `wf-explore` |
| 承認済みの計画を実装する | `wf-implement` |
| 実装後の検証証跡を作る | `wf-verify` |
| 差分を人間レビューへ渡せるか判定する | `wf-review` |
| review 指摘の戻り先を決める | `wf-review-triage` |
| 現在のコードの責務、契約、設計理由だけをコメントへ記録する | `document-code-intent` |
| 日本語の README、ガイド、仕様書などを作成・改訂する | `write-japanese-docs` |
| 人間の判断だけを回答可能な質問へ直す | `idiot` |
| 長い作業を別 agent や別 session へ渡す | `handoff` |
| 新規プロジェクトへ AI 作業用の文書と規則を追加する | `scaffold-project` |
| 文書、repo 内 skill、または workflow の整合を監査する | 対象に応じた `audit-*` |
| 成熟済みリポジトリの運用資産を共通 workflow へ寄せる | `migrate-workflow` |

自然文で呼び出せる skill も工程 workflow は代行しません。たとえば `audit-docs` が実装上の問題を見つけても、文書監査の中ではコードを修正しません。問題の内容に応じて実装や検証の workflow を案内します。

## Skill 一覧

### Main Workflow

| Skill | 役割 |
| --- | --- |
| `wf-explore` | 実装前の調査から pre-implementation review までを進める。その結果を計画と人間の判断事項にまとめる。人間が計画を承認するまでは実装を始めない。 |
| `wf-implement` | 人間が承認した計画を authority として実装し、計画の範囲内で対応テストから reviewable gate までを進める。 |
| `wf-verify` | repo 内の `test_runner` が必要な検証範囲を決め、コマンドの結果を検証証跡として返す。 |
| `wf-review` | 計画と差分を照合する。テストや文書根拠などの証跡も確認し、人間レビューへ進める状態か判定する。 |
| `wf-review-triage` | review で受けた指摘を分類する。そのうえで、実装や検証などの適切な工程へ戻す。 |

### Writing And Handoff

| Skill | 役割 |
| --- | --- |
| `write-japanese-docs` | 読者と利用場面に合わせて日本語文書を作成・改訂する。対象は README や仕様書など、人間が読む文書である。創作や翻訳だけの依頼には使わない。 |
| `feedback-to-criteria` | Codex の提案や生成物へのフィードバックを分析し、今回だけの修正と再利用可能な判断基準へ分ける。 |
| `idiot` | 既存の blocked 理由や未確認事項を、人間が答えられる判断質問へ変える。仕様決定や実装は行わない。 |
| `handoff` | 次の agent や session が作業を再開できるように、作業中に得た計画と証跡を packet へまとめる。 |

### Implementation Support

| Skill | 役割 |
| --- | --- |
| `document-code-intent` | 実装変更に合わせ、現在のコードの責務、契約、設計理由をコメントへ記録する。ユーザーの指示や今回の変更理由を、変更前後の差分説明としてソースコメントへ残さない。各テストには目的、対象、前提の三項目を必ず記載する。通常の実装やコードレビューは代行しない。 |

### Review Support

| Skill | 役割 |
| --- | --- |
| `review-tests` | `test_reviewer` が実装済み test artifact を read-only で確認する。確認対象は oracle と境界に加え、assertion の弱体化や flakiness の候補である。テスト計画だけを扱う `wf-explore` では使わない。 |

### Scaffold And Audit

| Skill | 役割 |
| --- | --- |
| `scaffold-project` | 新規プロジェクトや文書が少ないプロジェクトへ、AI coding agent が作業するための基本文書を作る。その中には仕様根拠や作業契約が含まれる。 |
| `scaffold-agent-prep-scout` | `wf-explore` の前処理を担う read-only prep scout を作り、委譲に必要な repo-local supplement と evidence 記録欄も整える。 |
| `scaffold-agent-test-runner` | repo 固有の検証コマンドを実行する `test_runner` custom agent と検証手順を作る。 |
| `scaffold-agent-reviewer` | repo 固有の専門 reviewer を作り、review skill と routing も整える。 |
| `audit-docs` | README などのプロジェクト文書を監査し、矛盾や古い前提を見つける。そのうち正しい内容が一意に決まるものは修正または backport する。 |
| `audit-repo-skill` | repo 内の AGENTS.md と agent 資材を監査する。役割や検証手順の正しい内容が一意に決まる場合は同じ作業内で直す。 |
| `audit-workflow` | 一時 worktree 上の仮想 Main Agent が `wf-*` workflow を完走できるか検証し、repo-local の不足を scaffold または audit skill で補う。 |
| `migrate-workflow` | 成熟済み repo の運用資産を分類する。そのうえで、共通 workflow へ委譲する範囲と repo に残す範囲を計画する。対象ファイルは変更しない。 |

### Subagent Contract

| Skill | 役割 |
| --- | --- |
| `subagent-orchestration` | Main Agent が subagent へ作業を渡す際の契約を定める。契約には ownership と context のほか、戻り値や停止条件を含める。 |
| `subagent-execution` | subagent が委譲 packet を authority とし、assigned scope を広げずに `done` または `blocked` を返すための実行規約を定める。 |

## 基本ワークフロー

通常の実装は、計画に対する人間承認を境に、調査と実装を分けます。

```text
wf-explore
  -> pre-implementation review
  -> human approval
  -> wf-implement
     -> formatter / format check（repo-local 規則で Main Agent 担当の場合）
     -> wf-verify
     -> specialist review / E2E / visual verification（必要な場合）
     -> audit-docs
     -> wf-review
        -> review-tests（test artifact を変更した場合）
        -> repo-local reviewable gate
  -> human review
```

まず `wf-explore` はコードとテストを調査します。仕様根拠や作業契約などの関連文書も確認します。調査結果をもとに変更範囲と検証方法を決め、未回答の判断事項とともに計画メモへ残します。計画が人間に承認されたら、その計画メモを `wf-implement` へ渡します。

実装後の検証は repo 内の `test_runner` へ委譲します。ただし、repo-local 規則が formatter または format check を Main Agent の担当としている場合は、Main Agent が直接実行します。

その後、`wf-review` が実装と検証の証跡を確認します。実装済み test artifact が変わっている場合は、まず共通の `test_reviewer` へ `review-tests` を委譲します。その結果を repo-local reviewable gate へ渡します。

review 後に問題が見つかった場合は、`wf-review-triage` が戻り先を決めます。

| 指摘の種類 | 戻り先 |
| --- | --- |
| 承認済み計画内の修正 | `wf-implement` |
| 検証証跡の不足 | `wf-verify` |
| 事実、文書根拠、計画の不足 | `wf-explore` |
| リスク受容や仕様選択 | `idiot` または人間判断 |
| 専門領域の再確認 | 対応する specialist reviewer |

## 文書の保存先

`scaffold-project` は、長く参照する根拠と個別作業の状態を別の場所に保存します。

| path | 保存する内容 | 主に読む workflow |
| --- | --- | --- |
| `docs/spec/` | プロジェクトの目的、要件、architecture、画面責務、判断ログなどの仕様根拠 | `wf-explore`、`audit-docs` |
| `docs/contract/` | AI 利用ルール、検証コマンド、review 条件、workflow map、安全境界などの作業契約 | `wf-explore`、`wf-implement`、`audit-docs` |
| `docs/work/` | `<task-id>.md` と `<task-id>.state.json` からなる短命な作業コンテクスト | 実行中の `wf-*` workflow |

作業方針と調査メモは Markdown に置きます。state file には機械的に扱う情報だけを保存します。具体的には進捗や対象ファイルのほか、コマンドの結果と Markdown への参照が対象です。

作業が完了したら、後続作業でも必要な内容を `docs/spec/` または `docs/contract/` へ backport します。その後、個別の作業ファイルは削除できます。

## 代表的な使い方

### 日本語文書を作成・改訂する

`write-japanese-docs` は人間が読む日本語文書を対象にします。たとえば README のほか、操作ガイドや仕様書にも使えます。

1. 対象文書と隣接文書を読み、表記規則と事実の根拠を確認する。
2. 読者と利用場面を定め、読後に行う判断または操作を明らかにする。
3. 既存構成を尊重しつつ、不足する説明と情報の順序を直す。
4. リンクや path など、文書内の具体的な記述を根拠と照合する。
5. repo に文書検査があれば実行し、なければ差分とローカルリンクを確認する。

ただし、文章を変更しないレビューには使いません。翻訳だけの依頼や創作も対象外です。ソースコードの実装には別の workflow を使います。

### 新規プロジェクトへ AI 作業環境を用意する

まず `scaffold-project` で基本文書を作ります。基本文書には仕様根拠と作業契約のほか、AGENTS.md や作業コンテクストの雛形が含まれます。その後、リポジトリの作業分担に応じて次の agent を追加します。

- 実装前の事実確認を分離する場合: `scaffold-agent-prep-scout`
- 検証を実装者から分離する場合: `scaffold-agent-test-runner`
- UI や permission などの専門 review が必要な場合: `scaffold-agent-reviewer`

最後に `audit-repo-skill` を使います。ここでは skill と agent の役割を確認し、配布時の path や権限境界に不整合がないか点検します。

### バグ修正や小さな機能追加を進める

1. `$wf-explore` で既存実装を調べ、テストと関連文書も確認して計画を作る。
2. pre-implementation reviewer の指摘を計画へ反映し、人間が計画を承認する。
3. `$wf-implement` で計画範囲内の実装と対応テストを行う。
4. repo-local 規則に従って formatter と `wf-verify` を進める。その後、必要に応じて専門 review や E2E を実行する。
5. `audit-docs` で長期保存すべき事実を仕様根拠または作業契約へ backport する。
6. `wf-review` で、人間レビューへ渡せる差分と証跡が揃っているか判定する。

ただし、専門 reviewer の指摘によって scope や仕様が変わる場合は、そのまま追加実装へ取り込みません。この場合は追加の `wf-explore` または人間判断へ戻します。

### Review 指摘を受けて再修正する

`wf-review-triage` は review 指摘を七つの区分へ分類します。たとえば、承認済み計画の範囲に収まる指摘は `fix-in-plan` です。この区分だけを再実装の scope とし、それ以外の指摘は前述の戻り先に渡します。

### 長い作業を別 agent や session へ渡す

`handoff` は次の担当者が必要とする authority と証跡を packet にします。まず、読むべきファイルと変更してはいけない範囲を示します。次に、完了条件と blocked 条件を記載します。未承認の計画や未回答の判断は authority に含めず、Open Items として分けます。

### Repo 内の運用資産を点検する

点検対象によって audit skill を選びます。

| 点検対象 | Skill | 結果 |
| --- | --- | --- |
| README、仕様根拠、作業契約、作業 state | `audit-docs` | 矛盾、古い前提、backport 候補と、一意に決まる文書修正 |
| AGENTS.md、repo-local skill、custom agent、review routing | `audit-repo-skill` | 役割重複、権限漏れ、配布上の問題と、一意に決まる修正 |
| `wf-*` workflow の完走可否 | `audit-workflow` | 一時 worktree での Workflow Trace と repo-local 不足の補正 |
| 成熟済み repo の共通 workflow への移行 | `migrate-workflow` | 資産ごとの移行先、残置範囲、参照更新順、削除条件 |

`audit-workflow` は一時 worktree 上で仮想 Main Agent を動かします。repo-local の不足は scaffold または audit skill で補正できますが、共通 skill 側の不足はその場で変更せず、対象 skill と修正案を報告します。

## Agent の役割境界

| 担当 | 行うこと | 行わないこと |
| --- | --- | --- |
| prep scout | `wf-explore` の前に事実と計画候補を read-only で集める | 実装、検証、文書更新、採用判断、計画確定 |
| `test_runner` | repo 固有の検証コマンドを実行し、証跡を返す | 修正、review 判定 |
| specialist reviewer | 専門領域の findings と blocking 状態を返す | 修正、検証実行、release、merge、risk acceptance |
| `test_reviewer` | 実装済み test artifact の oracle、境界、弱体化、flakiness 候補を確認する | 検証実行、修正、pre-implementation review |
| repo-local reviewable gate | 証跡を照合し、review 可能条件と次の routing を判定する | 証跡のない代替判定、repo 固有の設計判断の単独承認 |
| `project_doc_auditor` | 文書と実装証跡を read-only で監査し、修正候補を返す | 文書編集、実装、検証、review 判定 |

`test_runner` は同じ `wf-implement` の中で最初の session を再利用します。ただし、古い checkout や壊れた環境を使っている場合は結果を信頼できません。その場合に限って新しい session を使い、変更理由を検証証跡に残します。reviewable gate の最終判定では review iteration ごとに新しい reviewer session を使うのが原則です。

## 運用メモ

- 新しい skill には最低限 `SKILL.md` を置き、必要に応じて `agents/openai.yaml` を追加する。
- skill を追加または大きく更新したら、`quick_validate.py` で検証し、README の一覧と routing も更新する。
- skill 本文や公開文書には、個人環境の checkout 先などのローカルフルパスを固定しない。
- コミットはユーザーが明示した場合だけ行う。

## License

MIT License. See [LICENSE](./LICENSE).
