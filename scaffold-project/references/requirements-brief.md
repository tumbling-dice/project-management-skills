# Requirements Briefの作成手順

`docs/project/requirements-brief.md` を作るときに使う。

## 目的

Requirements Briefは、PJ Charterを業務上の振る舞い、権限境界、データ概念、最初の検証候補へ落とすための文書である。すべての要件が確定する前でも使える形にする。

UIを持つPJでは、Requirements Briefにすべての画面詳細を詰め込まず、画面責務、主要状態、E2E候補を `docs/project/screen-catalog.md` へ分ける。visual baselineやscreenshot reviewを早期に使う場合は、安定仕様を `docs/project/screen-contract.md` へ分ける。

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
- screen catalogは画面詳細設計やデザインシステムの代替にしない。
- 法令、規制、契約、セキュリティポリシー、金銭移動に関わる要件は、ユーザーが明示した後だけ人間確認済みとして扱う。
