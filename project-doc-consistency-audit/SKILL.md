---
name: project-doc-consistency-audit
description: ユーザーが自然文で、README、AGENTS、PJ文書、検証手順、review条件、作業メモの矛盾、古い前提、未決事項、実装や検証手順との食い違いを点検したいと頼んだ場合に使う。workflow-router のrouting結果、または $project-doc-consistency-audit の明示でも使う。実PJでは project_doc_auditor custom agentへ委譲する。修正は行わず、根拠資料として使える状態か、戻り先と更新候補を整理する。
---

# Project Doc Consistency Audit

このskillは、PJ文書群が調査や実装計画の根拠資料として使える状態かを点検するaudit workflowです。文書を修正せず、矛盾、古い前提、未決事項、欠けている根拠、実装や検証手順との食い違いを見つけ、次に戻すworkflowを整理します。

## 実行形態

実PJでは、Main Agentがこのskillを直接実行してはいけません。必ず `project_doc_auditor` custom agentへ委譲して実行します。

- Main Agentがこのskillを読んだ場合は、自分で文書auditせず、audit目的、対象文書、関連する実装/検証手順の代表ファイル、既知の文書不整合候補を短くまとめて `project_doc_auditor` へ渡します。
- `project_doc_auditor` custom agentが使えない場合は、`audit_status: blocked` とし、必要なagentが無いことを報告します。
- 実PJでは、同一Main Agentによる代替auditを行いません。代替auditは、このskill自体の開発・検証で明示された場合だけ行います。
- `project_doc_auditor` の返答を受けた後、Main Agentが戻り先workflowや人間判断を扱います。

## 使う場面

- `project-startup-scaffold` で作った文書群を、実装前の根拠として使えるか確認したい。
- `investigation-workflow` や `implementation-plan-gate` で、文書不整合候補が見つかった。
- バグ修正や仕様変更の前に、要件、設計、AGENTS、検証手順、review条件が食い違っていないか見たい。
- README、PJ文書、AGENTS、検証docs、review docs、作業メモのどれを信じてよいか整理したい。
- 長く更新されていない文書や、未決事項が放置されていないか確認したい。

## 使わない場面

- 文書を実際に更新する場合。
- 実装、テスト更新、検証実行、review判定を行う場合。
- repo内skillやcustom agentの整合を点検する場合。その場合は `$repo-skill-audit` を使います。
- 実装計画を作る場合。その場合は `implementation-plan-gate` を使います。

## 入力

audit目的に応じて、次のうち関係するものを確認します。すべてを読む必要はありません。

- `README.md`
- `AGENTS.md`
- `docs/project/pj-charter.md`
- `docs/project/requirements-brief.md`
- `docs/project/architecture-brief.md`
- `docs/ai/ai-usage-note.md`
- `docs/review/reviewable-gate.md`
- `docs/verification/`
- `docs/work/` の代表的な調査、計画、検証、review成果物
- repo固有のdocs
- project manifest、CI workflow、主要設定、代表的な実装ファイル

対象文書が存在しない場合は、欠落として記録します。存在しないことだけで止まらず、audit目的に対する影響を分類します。

## Audit観点

### 文書間の整合

- PJ目的、MVP、非対象範囲、成功条件が文書間で矛盾していないか。
- requirements、architecture、reviewable gate、verification docs の前提が食い違っていないか。
- AGENTSの作業ルールが、READMEやPJ文書と矛盾していないか。
- 確定事項、仮説、未決事項が混ざっていないか。

### 文書と実装/検証手順の整合

- 文書に書かれた技術構成、主要コマンド、検証手順がrepo内のmanifest、CI、script、実装と大きく食い違っていないか。
- 仕様や業務ルールが、代表的な実装ファイルやテストから見える挙動と矛盾していないか。
- review条件や検証手順が、現在のworkflowで実行できる粒度になっているか。

### 未決事項と根拠不足

- 実装計画の根拠に必要な文書が欠けていないか。
- `要確認`、`未決`、`仮説` が放置され、実装scopeや期待動作を曖昧にしていないか。
- 人間判断、追加調査、文書更新のどれで解消すべきか分けられているか。

### 安全境界

- secrets、credential、本番DB接続情報、本番ログの生データが文書に含まれていないか。
- auth、permission、tenant、PII、secret、ログ、外部入力、release、risk acceptance の扱いが曖昧なまま実装根拠になっていないか。
- AIがrelease、merge、本番操作、risk acceptanceを承認する記述になっていないか。

## 手順

1. audit目的と対象範囲を確認する。
2. 関係する文書と、必要な実装/検証手順の代表ファイルを列挙する。
3. 文書ごとに、確定事項、仮説、未決事項、参照先、更新日の手がかりを確認する。
4. Audit観点ごとにfindingを記録する。
5. findingをseverity、根拠、影響、戻り先で分類する。
6. 修正は行わず、次に実行すべきworkflowや人間判断を整理する。
7. ユーザーが成果物保存を求めた場合だけ、PJ慣習に従ってaudit結果を保存する。

## Severity

- `blocking`: 実装計画の根拠にできない矛盾、危険な安全境界の欠落、AIが承認してはいけない判断が文書に含まれる。
- `high`: 次に該当領域の実装やレビューを行う前に直すべき文書不整合。
- `medium`: 誤解や手戻りを生む可能性がある古い前提、未決事項、リンク切れ、検証手順の不足。
- `low`: 表記、重複、配置、読みやすさの問題。

## 戻り先

- 事実不足、実装との食い違いが原因: `investigation-workflow`
- 期待動作、scope、非対象範囲、テスト方針の整理が必要: `implementation-plan-gate`
- 人間の仕様判断、risk acceptance、scope決定が必要: `decision-clarification-workflow` または human decision
- 文書更新方針を別途計画したい: future doc update plan workflow
- repo内skillやagentの整合問題: `repo-skill-audit`
- 追加対応なし: no action

## 出力形式

```md
# Project Doc Consistency Audit

## Status

audit_status: pass / findings / blocked

## Scope

- audit purpose:
- checked docs:
- checked implementation / verification references:
- not checked:
- reason:

## Findings

- id:
  severity: blocking / high / medium / low
  category: doc-conflict / stale-assumption / missing-doc / unresolved-decision / implementation-mismatch / verification-mismatch / safety-boundary
  docs:
  evidence:
  impact:
  recommended next workflow:
  human decision:

## Positive Checks

- check:
  evidence:

## Open Questions

- question:
  why it matters:
  next owner:

## Suggested Update Order

- step:
  reason:

## Next Step

- no action / investigation-workflow / implementation-plan-gate / decision-clarification-workflow / repo-skill-audit / human decision
```

## 禁止事項

- audit中に文書更新、実装修正、テスト更新、検証実行、review判定を始めない。
- 文書が正しいと仮定して、実装や検証手順との矛盾を無視しない。
- 未決事項や仮説を確定事項として扱わない。
- secrets、credential、本番ログの生データを出力へ複製しない。
- release、merge、本番操作、risk acceptanceを承認しない。
- すべての文書を機械的に読むことを目的化せず、audit目的に関係する根拠を優先する。

## 完了報告

最後に次を報告します。

- `audit_status`
- blocking / high findingの有無
- 主な文書不整合、根拠不足、未決事項
- 未確認範囲
- 推奨更新順
- 次の戻り先
