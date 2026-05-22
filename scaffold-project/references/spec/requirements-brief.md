# Requirements Briefの作成手順

`docs/spec/requirements-brief.md` を作るときに使う。

## 目的

Requirements Briefは、PJ Charterを業務上の振る舞い、権限境界、データ概念、最初の検証候補へ落とすための文書である。すべての要件が確定する前でも使える形にする。

UIを持つPJでは、Requirements Briefにすべての画面詳細を詰め込まず、画面責務、主要状態、E2E候補を `docs/spec/screen-catalog.md` へ分ける。visual baselineやscreenshot reviewを早期に使う場合は、対象画面ごとの安定仕様を `docs/spec/screens/<screen-id>.md` へ分ける。UIの共通token、theme color、component使用条件を固定したい場合は `docs/spec/design-system.md` へ分ける。AIにUI実装、修正、visual pass準備を任せる場合は `docs/contract/ui-implementation-rules.md` を作る。

## 必須セクション

- `前提`
- `主要ユースケース`
- `業務ルール`
- `権限`
- `データ`
- `外部連携`
- `非機能要件`
- `E2E候補シナリオ`
- `非対象範囲`
- `確定事項`
- `仮説`
- `未決事項`
- `人間が判断する点`

## ルール

- 実在する顧客レコードや個人情報は含めない。
- 確定した業務ルールと推測した業務ルールを分ける。
- 権限とtenant境界は、未決定でも論点として書く。
- E2E候補は実装詳細ではなく、ユーザーから見えるflowにする。
- UIを持つPJでは、ユースケースを画面責務と主要状態へ分解する導線を残す。
- screen catalogは画面詳細設計やデザインシステムの代替にしない。画面固有の安定仕様は対象画面ごとのscreen specへ分ける。
- design-systemは完全なブランドガイドの代替にしない。初期段階では、UIが満たす共通token、theme、component使用条件に絞る。AI coding agent向けの実装禁止事項や確認手順は `ui-implementation-rules.md`、画面固有の例外やvisual baselineは `docs/spec/screens/<screen-id>.md` へ分ける。
- 法令、規制、契約、セキュリティポリシー、金銭移動に関わる要件は、ユーザーが明示した後だけ人間確認済みとして扱う。
