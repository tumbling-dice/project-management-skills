# Screen Spec: [screen-or-route] 要確認

## 目的

この文書は、1画面または1routeだけの安定仕様、変えてよい範囲、変えてはいけない導線や状態を記録する。
複数画面の一覧は `docs/spec/screen-catalog.md` に置き、画面ごとの詳細は `docs/spec/screens/<screen-id>.md` のように分ける。
画面横断のtoken、theme、component使用条件は `design-system.md` に置く。AIがUI実装時に守る作業ルールは `docs/contract/ui-implementation-rules.md` に置く。
この文書には画面固有のlayout、visual anchor、asset期待、visual baseline条件だけを残す。

## Identity

- screen id:
- route / entry point:
- primary user:
- primary task:
- related catalog entry:

## Design System参照

- 共通token:
- theme:
- component使用条件:
- icon / asset方針:
- この画面での例外:

## Stable Behavior

- 安定させる振る舞い:
- 変えてはいけない導線:
- permission / auth state:
- data state:

## Stable Layout / Visual

- 安定させる見た目 / レイアウト:
- 必須のvisual anchor:
- asset / iconの期待:
- 情報密度:
- responsive priority:

## Allowed / Forbidden Changes

- 変えてよい範囲:
- 変えてはいけない範囲:
- 画面固有の禁止代替:

## Coverage

- 状態のcoverage:
- viewportのcoverage:
- 関連テスト:

## Screenshot / Visual Baseline

- 必須のvisual anchorが欠けている。
- 必須の画像、icon、chart、map、media previewがgradient、emoji、灰色box、空白で代用されている。
- この画面で比較すべき情報が、指定外のcard gridや分断されたpanelに変わっている。
- この画面の主タスクより装飾、hero、余白、背景表現が目立っている。
- overflow、情報階層、密度、必須asset、responsive behaviorを確認せずに承認している。

## Review Notes

- 要確認

## 人間が判断する点

- 要確認
