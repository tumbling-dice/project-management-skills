---
name: ui-mock-contract
description: ユーザーが自然文で、UIの目的から画像モックを作り、$scaffold-project で定義される screen-catalog.md や対象画面のscreen specなどのレイアウト・デザイン文書を補強したいと頼んだ場合に使う。$ui-mock-contract の明示でも使う。このskillは必ず $imagegen を使ってUI mock screenshotを生成し、画像そのものを最終仕様にせず、Design Brief、Layout Contract、Asset Contract、Component Contract、Visual Acceptance Criteriaとして仕様根拠へ反映する。実装、検証、review判定は行わない。
---

# ui-mock-contract

このskillは、UI実装前に「見た目の方向性」を画像で具体化し、その画像から仕様根拠へ残せるレイアウト・デザイン契約を作るための準備工程である。

目的は、生成画像に似せて実装させることではない。画像モックから、layout、asset、component、禁止代替、visual acceptance criteriaを抽出し、`$scaffold-project` が作る `docs/spec/screen-catalog.md` と対象画面のscreen specを補強する。

## 使う場面

- UIの目的はあるが、layout、情報密度、非テキスト要素、visual anchorが言語化されていない。
- `$scaffold-project` で作った、または作る予定のUI文書へ、layout、density、visual anchor、asset方針を追加したい。
- エンジニア向けに、実装前のDesign BriefやLayout Contractを仕様根拠として残したい。
- 画像モックを使って、アイコン、画像、図版、chart、media panelなどの必要性を棚卸ししたい。
- 実装時に、画像、アイコン、図版が黙って省略されることを防ぎたい。
- `$imagegen` を使ったUI mock screenshotを、実装可能な契約へ変換したい。

## 使わない場面

- すぐにUIを実装する場合。
- 実装担当へのhandoffだけを作る場合。
- 既存差分のvisual reviewをする場合。
- screenshotが契約を満たしているか判定する場合。
- logo、icon、illustrationなど単体assetを生成したい場合。
- 既存design systemやFigmaだけで十分に実装契約が決まっており、画像モックを作らない方針が明示されている場合。

## 基本方針

- このskillを使う場合は、必ず `$imagegen` でUI mock screenshotを生成する。
- 画像モックはauthorityではない。authorityは、画像から抽出した契約である。
- 主な更新先は `docs/spec/screen-catalog.md` と、対象画面ごとの `docs/spec/screens/<screen-id>.md` である。repoに別の配置がある場合は、その配置に合わせる。
- 対象文書がない場合は、`$scaffold-project` の `assets/templates/spec/screen-catalog.md` と `assets/templates/spec/screen-spec.md` 相当の構成で、対象画面ごとに作成する。
- 画像生成前に、既存UI、design token、icon library、使用可能なassetを確認する。
- 既存UI制約を無視した画像モックを作らない。
- 画像内の非テキスト要素を、実装義務、任意要素、採用しない要素へ分ける。
- 画像、アイコン、図版、chart、map、media previewなどを、黙ってgradient、灰色box、emoji、text labelへ置き換えさせない。
- 不足情報が実装品質に影響する場合は、画像生成前に少数の質問へ絞る。

## 入力

確認できる範囲で次を集める。

- UIの目的、対象ユーザー、主タスク
- 既存の `screen-catalog.md`、対象画面のscreen spec、または同等のUI文書
- surface type: app / admin / dashboard / editor / viewer / landing / portfolio / ecommerce / game UI など
- 既存画面、既存component、design token、色、spacing、typography、icon library
- 使用可能な画像、illustration、logo、avatar、product media、chart、map、preview asset
- 必須テキスト、避けたい見た目、brandやtoneの制約
- 対象viewport、responsive上の優先順位

## 手順

1. UIの目的とsurface typeを決める。
2. 既存UI制約を読む。
   - design system、component、tokens、CSS framework、icon library、既存assetを確認する。
   - 既存制約が見つからない場合は、その事実を明記する。
3. 画像生成前のDesign Seedを作る。
   - 情報密度、layout model、visual hierarchy、使ってよい非テキスト要素、避ける表現を短く固定する。
4. `$imagegen` を使ってUI mock screenshotを生成する。
   - use caseは `ui-mockup` とする。
   - 既存UI制約、surface type、主タスク、非テキスト要素、避ける表現をpromptへ入れる。
   - 画像内テキストは正確性を期待しすぎず、layoutとvisual anchorの検討材料として扱う。
5. Mock Breakdownを作る。
   - layout regions、情報階層、density、container、非テキスト要素、visual anchor、採用しない要素、代替禁止を抽出する。
6. 契約へ変換する。
   - Design Brief
   - Layout Contract
   - Asset Contract
   - Component Contract
   - Visual Acceptance Criteria
7. 仕様根拠へ反映する。
   - `screen-catalog.md` には、画面責務、主要状態、responsive expectations、accessibility notes、E2E / visual check candidateを追加する。
   - 対象画面のscreen specには、Stable visual / layout expectations、Allowed changes、Forbidden changes、State coverage、Viewport coverage、Screenshot / visual baseline、Review notesを追加する。
   - 文書へ直接書けない場合は、貼り付け可能なDocumentation Updateとして出す。

## imagegen prompt方針

promptには少なくとも次を含める。

```text
Use case: ui-mockup
Asset type: UI mock screenshot for contract extraction
Primary request: <UI目的と主タスク>
Surface type: <app/admin/dashboard/etc>
Existing UI constraints: <tokens/components/icon library/assets>
Layout direction: <main regions and hierarchy>
Non-text elements to consider: <icons/images/illustrations/charts/media>
Density: <compact/standard/spacious and why>
Constraints: create a plausible implementable UI, not a marketing poster
Avoid: decorative gradients unless justified, card grids unless repeated items require cards, pill UI for ordinary controls, nested cards, placeholder gray boxes
```

## Mock Breakdown

画像生成後に、次を必ず書く。

```md
## Mock Breakdown

### Layout

- regions:
- navigation:
- primary workspace:
- supporting panels:
- repeated content model:

### Hierarchy And Density

- primary focus:
- secondary information:
- density:
- spacing implications:

### Asset Inventory

- icons:
- images:
- illustrations:
- avatars/logos:
- charts/maps/media:
- background or texture:

### Visual Anchors

- elements that prevent the screen from becoming text-only:
- minimum non-text elements that must remain:

### Adopt

- contract decisions to keep:

### Do Not Adopt

- generated details that should not become implementation requirements:

### Forbidden Substitutions

- elements that must not be replaced with text, gradient, emoji, empty box, or generic card:
```

## 出力形式

```md
# UI Mock Contract Documentation Update

## Status

contract_status: ready / blocked

## Source

- ui goal:
- surface type:
- generated mock:
- existing UI constraints:
- target docs:
- open assumptions:

## Design Seed

- primary user task:
- target user:
- density:
- tone constraints:
- visual direction:
- avoid:

## Mock Breakdown

<!-- Follow the Mock Breakdown format. -->

## Design Brief

- purpose:
- user task:
- information hierarchy:
- density:
- visual tone:
- non-goals:

## Layout Contract

- regions:
- navigation:
- main workspace:
- supporting panels:
- repeated item rules:
- empty/loading/error states:
- responsive behavior:

## Asset Contract

- required icons:
- required images:
- required illustrations:
- required avatars/logos:
- required charts/maps/media:
- asset source:
- aspect ratios and crop behavior:
- fallback rules:
- fallback allowed:
- blocked if unavailable:

## Component Contract

- buttons:
- cards:
- tables/lists:
- badges/pills:
- tabs/filters:
- forms:
- charts/media panels:
- dialogs/drawers:

## Visual Acceptance Criteria

- must show:
- must not show:
- desktop checks:
- mobile checks:
- screenshot review fail conditions:

## Screen Catalog Update

- screen:
- purpose:
- primary user action:
- entry points:
- data sources:
- main states:
- empty / loading / error states:
- permission / auth state:
- responsive expectations:
- accessibility notes:
- E2E / visual check candidate:
- out of scope:
- open questions:

## Screen Contract Update

- screen:
- stable behavior:
- stable visual / layout expectations:
- allowed changes:
- forbidden changes:
- state coverage:
- viewport coverage:
- screenshot / visual baseline:
- related tests:
- review notes:

## Later Workflow Notes

- docs to read:
- stable contracts:
- must not:
- blocked when:
```

## 禁止事項

- 画像モックを最終仕様として扱わない。
- 画像に似ているかどうかだけを受け入れ基準にしない。
- 既存UI制約を読まずに画像生成へ進まない。
- 画像内のasset、icon、illustrationを棚卸しせずに契約化しない。
- Asset Contractにある要素を、gradient、emoji、text label、灰色box、空白で代用してよいと書かない。
- 実装担当へのhandoffだけで終わらせず、仕様根拠へ反映する。
- 実装、検証、review判定をこのskill内で行わない。
- 「見た目をよくする」「モダンにする」だけの曖昧な指示を実装authorityにしない。

## 完了報告

最後に次を報告する。

- `contract_status`
- 生成した画像モックの扱い
- 作成または更新したUI文書
- 作成した契約の要点
- Asset Contractの要点
- blockedの場合の不足情報
