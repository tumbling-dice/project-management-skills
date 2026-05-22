# デザインシステムメモ

## 目的

UIの共通token、theme、component使用条件を記録する。
実装時に毎回見た目を作り直さず、既存の色、余白、typography、角丸、影、icon、assetの使い方へ揃えるための文書である。
AIがUI実装時に守る作業ルールは `docs/contract/ui-implementation-rules.md` に置く。
画面ごとの安定仕様、状態、visual baseline、例外は `docs/spec/screens/<screen-id>.md` に置く。

## 参照元

- 既存design system:
- component library:
- CSS framework:
- tokenの参照元:
- icon library:
- asset directory:
- Figma / design file:
- Storybook / preview:
- 未決事項:

## デザイントークン

### 色

- 背景:
- surface:
- border:
- text primary:
- text secondary:
- muted text:
- primary action:
- secondary action:
- accent:
- success:
- warning:
- danger:
- focus ring:
- disabled:

### 文字

- font family:
- 基本文字サイズ:
- 本文:
- 小さい文字:
- label:
- 見出し階層:
- 数値 / tabular text:
- line height:

### 余白

- base spacing unit:
- compact spacing:
- standard spacing:
- section spacing:
- form spacing:
- table / list spacing:

### 形状

- default radius:
- small radius:
- large radius:
- pill形状の使用条件:
- border width:
- shadow levels:

### 動き

- default duration:
- easing:
- reduced motion時の挙動:

## テーマルール

- light theme:
- dark theme:
- brand colors:
- high contrast:
- state colors:
- 使わない色 / 表現:

## Component使用ルール

### Button

- primary:
- secondary:
- destructive:
- icon button:
- disabled:
- loading:

### Card

- 使う条件:
- 使わない条件:
- header / body / footer rules:
- nested card policy:

### Table / List

- tableを使う条件:
- listを使う条件:
- row density:
- selection:
- empty state:

### Badge / Pill

- badgeの用途:
- pillの用途:
- 使わない対象:

### Forms

- label placement:
- help text:
- validation:
- error summary:

### Navigation

- primary navigation:
- secondary navigation:
- breadcrumbs:
- tabs:

### Icon / Image

- icon source:
- icon size:
- stroke / fill:
- image aspect ratios:
- crop behavior:
- alt text:
- fallback:

## 人間が判断する点

- 要確認
