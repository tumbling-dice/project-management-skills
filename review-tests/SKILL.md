---
name: review-tests
description: "`$wf-review` から実装済みのテスト差分を渡された場合だけ使う。テストのoracle、仕様上意味のある境界、flakiness候補、弱体化をread-onlyでレビューする。`wf-explore` のテスト計画レビュー、テスト実行、修正には使わない。"
---

# review-tests

このskillは、追加、更新、削除されたテストが単に存在して成功するだけでなく、承認済みの期待動作に対する誤実装を検出でき、再現可能に実行できるかをレビューするための共通専門reviewである。`$wf-review` が `test_reviewer` custom agentへ実装済みテストと証跡を渡して使う。

## Trigger

次のいずれかを含む実装差分を `$wf-review` が扱う場合に呼ぶ。

- テスト、fixture、test helper、snapshot、golden fileの追加、更新、削除
- skip、xfail、retry、timeout、filter、test discovery、assertion設定の変更
- 既存テストの対象範囲または成否を変える変更

テスト差分がなく、上記設定にも影響しない場合は呼ばない。実装前のテスト計画しかない `$wf-explore` では呼ばない。計画に対するpre-implementation reviewを代替しない。

## Inputs

Main Agentは `$subagent-orchestration` に従い、少なくとも次を委譲packetまたは参照先で渡す。

- 承認済み計画または人間が承認した変更範囲と、期待動作の根拠
- current diff、変更ファイル一覧、変更されたテストartifact
- テスト対象の実装差分と、判定に必要な既存実装
- 関連する既存テスト、fixture、helper、test設定
- 検証コマンド、結果、未実行検証と理由
- 非対象範囲、risk notes、再reviewなら前回findingと修正要約

期待動作、テスト差分、テスト対象の実装を特定できず、scope内の読取でも補えない場合は `blocked` として不足証跡を返す。テスト成功やcoverage値だけを十分な証跡としない。

## Review Method

変更された各テストartifactについて、次の順で確認する。

### 1. Required behaviorとtestの対応

- 承認済みの期待動作、回帰条件、失敗経路、状態遷移を、該当するtest caseと対応付ける。
- テストが変更対象を通過するだけでなく、誤った結果、状態、副作用、例外を観測して失敗するかを確認する。
- bug fixでは、修正前の誤動作を区別する入力とoracleになっているかを差分から確認する。修正後に成功した事実だけで回帰検出力を認定しない。
- production codeの品質は、テストが誤りを検出できるかの判断に必要な範囲だけ読む。

### 2. Oracleの意味と精度

- exact value、構造、状態変化、外部から観測できる副作用、具体的な例外型やerror情報など、要求された性質を拘束しているか確認する。
- existence、truthiness、型、単なる「例外が出ないこと」だけの確認は、要求された性質を十分に拘束する場合を除き弱いoracleとして扱う。
- assertion名だけで強弱を決めない。`assertTrue(predicate(x))` はpredicateの意味を読み、`assertEqual` でも期待値を実装と同じロジックから算出していれば独立したoracleとみなさない。
- custom assertionやhelperは定義まで辿り、実在、引数、失敗条件、診断内容を確認する。未定義、誤記、期待と異なるhelperはblocking findingとする。
- assertionが実行されない分岐、await漏れ、例外の握り潰し、mockした値の自己確認、常に真になる比較がないか確認する。

### 3. 意味のある境界と失敗経路

- 入力domain、状態、権限、順序、容量、error contractから、今回の変更を壊しうる同値partitionと境界を選ぶ。
- null、空、ゼロ、負数、最小／最大値を数えず、仕様上到達可能で期待動作が定義された値か、そのtestが新しい区別を検証するかを確認する。
- happy path、代表的な失敗経路、変更固有の境界の不足を探す。すべての一般的境界を機械的に要求しない。
- parameterized testやloopでは、各caseが実際に実行され、caseごとの失敗位置を識別でき、共有stateで相互汚染しないか確認する。

### 4. Stabilityとisolation

- wall clock、timezone、locale、乱数、実行順、並行処理、fixed sleep、file/network I/O、database、環境変数、global state、共有cache、外部serviceへの依存を探す。
- clock注入、seed固定、待機条件、temp directory、mock／fake、transaction、resource cleanup、state resetにより、意図したtest levelに応じて隔離されているか確認する。
- 静的なanti-patternはflakinessの候補として扱う。例えばtimeoutを試すsleepや、明示的なintegration testのI/Oを、利用しただけでflakyと断定しない。
- 反復実行結果や隔離環境の証跡があれば確認するが、このreviewer自身は検証コマンドを実行しない。動的証跡が必要なら `$wf-verify` へ戻す。

### 5. Test integrity

- test削除、skip／xfail追加、assertion削除、期待値の緩和、広すぎる例外受理、snapshotの無差別更新に承認済みの根拠があるか確認する。
- 既存のfailure signal、対象範囲、再現性を弱めていないか、新規テストの数やcoverage増加とは独立に確認する。
- 同じ実装詳細を複製するだけのtest、意味の重ならない大量の境界列挙、保守時に意図を判別できないfixtureをnon-blockingまたはblockingとして影響に応じて分類する。

## Finding Classification

次を `blocking` とする。

- 承認済みの変更動作または回帰条件を、誤実装でも通過するoracle
- scope内の重要な失敗経路または到達可能な境界が未検証で、変更の回帰を検出できない
- 未定義／誤用されたassertionやhelper、実行されないassertion、自己充足するmock／期待値
- 根拠のないtest削除、skip、assertion弱体化、failure signalの消失
- test levelに反する外部依存、非決定性、共有state、cleanup漏れにより、結果または他testを不安定にする具体的経路

次を `non-blocking` とする。

- 現在の要求は拘束できるが、重複、診断性、命名、fixture構造を改善できるもの
- 静的にはflakiness候補だが、隔離策があり失敗経路を特定できないもの
- 今回の承認scope外にある追加の境界やtest整理

期待動作、許容するintegration依存、scope外の追加coverage、flakiness riskの受容を既存証跡から一意に決められない場合は `human decision` とする。人間判断を理由にrelease、merge、risk acceptanceを代行しない。

## Output

`$subagent-execution` に従い、subagent応答の `result` とreview判定を分ける。`result: done` はレビューが完了した意味であり、testが通過した意味ではない。

```text
result: done | blocked
review_status: pass | blocked

Blocking findings:
- [B1] <file:line> — <誤りを見逃す／不安定になる具体的経路、根拠、戻り先>

Non-blocking findings:
- [N1] <file:line> — <影響と改善候補>

Human decisions:
- <判断事項、選択肢へ必要な根拠、戻り先>

Missing evidence:
- <不足artifactまたはnone>

Not checked:
- <scope外または確認不能範囲>

wf-review summary: <pass/blocked、主な根拠、次のownerを1-3文>
```

evidenceが揃いblocking findingがなければ `review_status: pass` とする。review自体を実施できるevidenceが不足していれば `result: blocked`、findingを確認できたが修正等が必要なら `result: done` かつ `review_status: blocked` とする。

戻り先は、テストまたは実装修正なら `$wf-implement`、動的検証不足なら `$wf-verify`、期待動作、影響範囲、根拠不足なら `$wf-explore`、risk acceptanceやscope変更ならhuman decisionとする。

## Boundaries

- ファイル編集、テスト／lint／build実行、snapshot更新、finding対応を行わない。
- coverage率、test数、成功件数だけでpassにしない。
- assertion method名、literal edge case、flakiness anti-patternの個数を品質scoreにしない。
- testの作者が人間かagentかを推定せず、作者によって判定基準を変えない。
- production implementationの一般code review、release、merge、risk acceptanceを行わない。
- `$wf-explore` の計画メモやテスト計画をレビューしない。

## Research Basis And Limits

設計根拠は Jhanglani et al., [“Beyond Test Presence: Assessing the Quality and Robustness of Agent-Generated Tests in Open-Source Projects”](https://arxiv.org/abs/2607.12068) である。同論文の三観点であるassertion strength、edge-case coverage、flakiness potentialを、個別差分の意味を読むreviewへ適用する。

論文自身が、assertion名やliteral検出はsemantic qualityのproxy、静的anti-patternはflakiness candidateにすぎず、Python／open-source／対象agent群からの一般化に限界があるとする。このskillでは論文の比率やtaxonomyを合否thresholdにせず、repo固有の仕様、helper、実行環境、動的証跡を優先する。
