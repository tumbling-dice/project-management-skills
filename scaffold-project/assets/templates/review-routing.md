# Review Routing

## 目的

差分の種類ごとに、必要な証跡、review owner、専門review、人間判断を分ける。

## Routing Table

| Change type | Required evidence | Review owner | Specialist review needed | Security / privacy / permission concern | Human decision needed | Do not approve by AI | Next workflow |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 |

## Always Escalate

- 認証、認可、tenant、PII、secret、ログの扱いが変わる変更:
- DB migration、データ削除、外部service操作:
- release、本番操作、risk acceptance:

## Notes

- 要確認
