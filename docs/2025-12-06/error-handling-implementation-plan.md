# エラーハンドリング実装方針

作成日: 2025-12-06

## 基本方針

### 1. エラーの分類

- **Railsアプリケーション内で起きたエラー** → 500系エラー
- **クライアントからの情報不足によるエラー** → 400系エラー
- **外部APIのエラー** → 状況に応じて振り分け
  - 認証・認可エラー（401, 403）→ そのまま400系を返す
  - その他の400系 → 502 Bad Gateway
  - 500系 → 502 Bad Gateway
  - タイムアウト → 504 Gateway Timeout

### 2. エラーハンドリングの場所

- **ApplicationControllerの`rescue_from`で補足**
  - コントローラーから呼び出されたメソッドで発生したエラーを全て補足
  - エラーの種類に応じた適切なHTTPステータスコードとメッセージを返す

### 3. メッセージ戦略

- **フロントエンド**: user-friendlyなメッセージを適切なエラーコードで返す
- **サーバー側**: 詳細なログ出力を正しく行う
- **i18nを使用**: エラーメッセージはi18nで管理

## エラークラス構造

### シンプルな2層構造

```
StandardError
└── ApplicationError (基底クラス)
    ├── BadRequestError (400)
    ├── UnauthorizedError (401)
    ├── ForbiddenError (403)
    ├── NotFoundError (404)
    ├── ValidationError (422)
    ├── InternalServerError (500)
    ├── BadGatewayError (502)
    ├── ServiceUnavailableError (503)
    └── GatewayTimeoutError (504)
```

### 特徴

- **階層は2層のみ**: StandardError → ApplicationError → 各エラー
- **モジュール固有のエラーは作らない**: 必要に応じてcontextで情報を付与
- **エラークラスは必要最小限**: 10個程度

## 実装詳細

### 1. ApplicationError基底クラス

**ファイル**: `app/errors/application_error.rb`

### 2. 各エラークラス

**ファイル**: `app/errors/[error_name]_error.rb`

### 3. ApplicationControllerの実装

**ファイル**: `app/controllers/application_controller.rb`

### 4. i18n設定

**ファイル**: `config/locales/errors.yml`

## 既存コードの修正

### 1. Infra::Http::Client
### 2. Infra::Http::Response
### 3. Authentication::BearerTokenExtractor

## 実装手順

1. エラークラスの作成
2. i18n設定
3. ApplicationControllerの修正
4. 既存コードの修正
5. テスト

