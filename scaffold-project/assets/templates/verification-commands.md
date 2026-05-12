# Verification Commands

## 方針

- 検証コマンドのsource of truthとして使う。
- 未実行の検証は、理由とriskを残す。
- network、secret、GUI、dev server、本番環境への接続要否を曖昧にしない。

## Commands

| Command | Purpose | When to run | Executor | Expected result | Quiet option | Timeout | Artifacts | Needs network / secret / GUI / dev server | Allowed in sandbox | Not run reason | Known warnings | Related workflow |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |

## Default Verification Set

- build:
- test:
- lint:
- typecheck:
- E2E:
- smoke:

## Human Decisions

- 要確認
