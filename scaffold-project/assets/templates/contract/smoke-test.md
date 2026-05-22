# Smoke Test Contract

AIまたはtest_runnerがsmoke testを実行または委譲するときの範囲、禁止事項、記録項目を定義する。

## Scope

- environment:
- accounts:
- main flows:

## Checks

- 権限不足ユーザーでアクセスできない:
- tenant違いのデータが見えない:
- 主要画面や応答に明らかな崩れがない:
- PII、token、secret、内部情報が表示またはログ出力されない:

## Do Not

- 本番環境で実行しない:
- 本番DBへ接続しない:
- secretや実顧客データを表示、保存、転記しない:
- 結果をrelease可否やrisk acceptanceとして扱わない:

## Evidence

- command / operation:
- result:
- artifact:
- not run and risk:
