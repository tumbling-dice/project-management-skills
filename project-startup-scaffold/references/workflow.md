# 立ち上げワークフロー

立ち上げ時に、どの文書をどの順でscaffoldするか決めるときに使います。

## 標準セッションの形

1. PJの状態を確認する:
   - 何を作るのか
   - 誰が使うのか
   - 最初に価値が出る範囲はどこか
   - 明示的な非対象範囲は何か
   - AIエージェントに触らせてはいけない環境、データ、操作は何か
2. 詳細なPJ文書より先に、暫定AI利用メモを作る。
3. PJ Charterを下書きする。
4. Charterを元にRequirementsを下書きし、不明点は見える場所に残す。
5. 技術嗜好だけでなくRequirementsからArchitectureメモを作る。
6. PJ境界とAI利用境界が見えてから `AGENTS.md` を下書きする。
7. 最初の小さなタスク用に、work-context、reviewable-gate、smoke-testのtemplateを作る。

## 最小文書セット

ユーザーが一通りの初稿を求めた場合は、このセットを使う:

```text
docs/ai/ai-usage-note.md
docs/project/pj-charter.md
docs/project/requirements-brief.md
docs/project/architecture-brief.md
AGENTS.md
docs/work/_template.md
docs/review/reviewable-gate.md
docs/verification/smoke-test.md
```

repoに既存の文書配置がある場合は、意図を保ったままpathを合わせる。

## 確認質問

文書内容が実際に変わる質問だけをする:

- 主なユーザーまたは運用者は誰か
- 最初のMVPで達成したい結果は何か
- 初回では変更してはいけないものは何か
- AI利用を禁止するデータや環境は何か
- build、test、lint、typecheck、local verificationに使える安全なコマンドは何か
- GitHub、別のチケットシステム、Markdown作業メモのどれを使うか

## 完了報告

完了時は次を報告する:

- 作成または更新したファイル
- 仮説として記録した前提
- `要確認` のまま残した判断
- 最初に試す小さなタスク候補
- 意図的に後回しにした文書
