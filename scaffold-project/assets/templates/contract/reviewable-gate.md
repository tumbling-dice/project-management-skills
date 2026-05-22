# Reviewable Gate

レビューに進めてよい差分かどうかの入口条件である。失敗中の検証や未整理の未実行検証がある差分は作業途中として扱う。

## 条件

- build / test / lint / typecheck など、repoで必要な検証証跡がある。
- 変更に対応するテストを追加または更新している。不要な場合は理由がある。
- テスト削除、skip、assertion弱体化で通していない。
- 未実行検証は理由とriskを記録している。
- auth、PII、secret、tenant、DB、外部service、release影響は `review-routing.md` に従って扱っている。

## Gate実装

- 方式: custom agent委譲 / gate summary
- pass条件:

## 例外扱い

既知の無関係な失敗がある場合は、作業コンテクストMarkdownに根拠、影響、risk、人間承認を記録し、state fileの `commands` に実行結果を記録する。
