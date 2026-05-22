# UI Implementation Rules

AIがUIを実装、修正、review準備するときの作業ルールである。
UIが満たす仕様は、承認済み作業コンテクストに記録された `docs/spec/design-system.md`、`docs/spec/screen-catalog.md`、対象画面の `docs/spec/screens/<screen-id>.md` を参照する。
`screen-catalog.md` は画面索引であり、全画面の詳細仕様を集約しない。画面固有の仕様は、1画面につき1つのscreen specへ分ける。

## Before Implementing UI

- 承認済み作業コンテクストで、UI対象画面、route、対象screen spec path、再確認条件を確認する。
- 作業コンテクストに記録された対象画面の `docs/spec/screens/<screen-id>.md` だけを読む。影響しない画面のscreen specは読まない。
- `docs/spec/screen-catalog.md` は、作業コンテクストで再確認対象に指定されている場合だけ読む。実装時に新しい対象画面を探すためには読まない。
- 既存component、token、CSS framework、icon library、asset方針を確認する。
- `docs/spec/design-system.md` のtoken、theme、component使用条件を確認する。
- 作業コンテクストにUI対象画面または対象screen spec pathがない場合は、実装scopeを広げず `wf-explore` または人間判断へ戻す。
- 実装中に追加の影響画面が見つかった場合は、勝手に対象へ加えず作業コンテクストへ `要確認` として残す。
- 不明な仕様は作業コンテクストへ `要確認` として残し、勝手に確定しない。

## Do Not

- tokenがある場合、新しいpaletteを勝手に作らない。
- 許可されていない装飾gradientを使わない。
- cardを初期値のlayout primitiveとして使わない。
- 通常のbutton、filter、tab、labelを初期値としてpill形状にしない。
- cardを入れ子にしない。
- 必須assetをgradient、emoji、灰色box、空白で代用しない。
- 2種類目のicon styleを追加しない。
- viewport幅に連動してfont sizeを変えない。
- 業務tool、dashboard、admin画面、editor内でhero風の大きすぎる余白を使わない。

## Review Before Screenshot / Visual Pass

- overflow、responsive behavior、情報密度を確認した。
- 必須asset、icon、chart、map、media previewが代替表示になっていない。
- 画面の主タスクより装飾、hero、背景表現が目立っていない。
- 対象画面のscreen specにあるscreenshot却下条件に該当しない。
