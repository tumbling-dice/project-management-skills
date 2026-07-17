# Custom Agent Authoring Baseline

repo-scoped custom agentは `.codex/agents/<agent-name>.toml`、個人用agentは `$CODEX_HOME/agents/` または `~/.codex/agents/` に置く。

## Required fields

```toml
name = "agent_name"
description = "Human-facing guidance for when Codex should use this agent."
developer_instructions = """
Goal:
- <outcome>

Evidence:
- <authoritative inputs>

Boundaries:
- <scope and approval limits>

Deliver:
- <result, evidence, and done/blocked conditions>
"""
```

`description` は主要なroleとtriggerを先頭に置く。`developer_instructions` は結果、必要なcontext、変更してはいけない境界、成功条件、出力を明記し、手順自体が要件でない限り細かな進め方を固定しない。

## Optional fields

- `nickname_candidates`: UI表示名が必要な場合だけ使う。
- `model`: 親sessionから継承させる場合は省略する。固定するなら、複雑な計画・実装・統合判断は `gpt-5.6`、read-heavyな探索・大量文書scan・補助reviewは `gpt-5.6-terra` を初期候補にし、代表taskで比較する。
- `model_reasoning_effort`: 省略時は親から継承する。`medium` を初期値、複雑なreviewやedge-case追跡は `high` を候補にし、品質差が測れた場合だけ `xhigh` または `max` を使う。
- `sandbox_mode`: reviewer、auditor、scout、test結果の読解は原則 `read-only`。編集責務を持つworkerだけ、親の権限境界を超えない範囲で `workspace-write` を検討する。
- `mcp_servers`、`skills.config`: そのroleに必要なtoolまたはSkillだけを露出する。

modelとreasoningを更新するときは、現在値をbaselineに同じ設定と一段低い設定を代表taskで比較する。成功率、必要な根拠、最終回答の完全性を先に評価し、token、latency、costの減少だけで採用しない。

## Boundaries

- read-only roleへ編集責務を与えない。
- safeなrepo内読取や指定scopeの作業を、重複した承認指示で止めない。
- 外部書込み、破壊操作、費用発生、scopeの実質的拡張は親へ戻す。
- roleに不要なtool、長い親会話、未採用の仮説を渡さない。
