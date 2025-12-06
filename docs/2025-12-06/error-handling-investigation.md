# エラーハンドリング調査結果

調査日: 2025-12-06

## 調査対象

- `app/controllers/` 配下のコントローラー
- `app/services/` 配下のサービス

## 現状のエラーハンドリング実装

### 1. ApplicationController

```1:10:app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_standard_error

  private

  def handle_standard_error(error)
    Rails.logger.error "Standard error occurred: #{error.message}\n#{error.backtrace.join("\n")}"
    render json: { error: "An unexpected error occurred" }, status: :internal_server_error
  end
end
```

**現状:**
- 全ての`StandardError`をキャッチして500エラーとして返している
- エラーの種類に関わらず、一律で`internal_server_error`を返している
- エラーメッセージは固定の「An unexpected error occurred」のみ

### 2. UsersController

```1:6:app/controllers/users_controller.rb
class UsersController < ApplicationController
  def setup
    result = Users::SetupService.call(auth_header: request.headers["Authorization"])
    render json: result, status: :ok
  end
end
```

**現状:**
- エラーハンドリングが実装されていない
- サービスから例外が発生した場合、`ApplicationController`の`handle_standard_error`で処理される

### 3. Infra::Http::Client

```40:52:app/services/infra/http/client.rb
      def handle_response(response)
        status = response.status
        case status
        when 200..299
          response.json
        when 400..499
          raise ClientError, response.body
        when 500..599
          raise ServerError, response.body
        else
          raise UnknownError, response.body
        end
      end
```

**現状:**
- `ClientError`、`ServerError`、`UnknownError`をraiseしているが、これらのクラスが定義されていない
- HTTPステータスコードに応じて適切なエラークラスをraiseしようとしているが、実装が不完全

### 4. Infra::Http::Response

```1:24:app/services/infra/http/response.rb
module Infra
  module Http
    class Response
      # カスタムエラークラスを定義
      class Error < StandardError; end

      attr_reader :status, :body, :header

      def initialize(net_http_response)
        raise ArgumentError, "net_http_response is required" if net_http_response.nil?

        # 複数のパターンに対応
        @status = extract_status(net_http_response)
        @body = extract_body(net_http_response)
        @header = extract_header(net_http_response)
      end

      def json
        raise Error, "status is not 2xx" unless success?
        return nil if status == 204
        @json ||= JSON.parse(body)
      rescue JSON::ParserError => e
        raise Error, "Failed to parse JSON: #{e.message}"
      end
```

**現状:**
- `Response::Error`という独自のエラークラスを定義している
- `StandardError`を継承しているが、他のエラークラスとの階層関係がない

### 5. Authentication::BearerTokenExtractor

```18:51:app/services/authentication/bearer_token_extractor.rb
  class BearerTokenExtractor
    class Error < StandardError; end
    class InvalidFormatError < Error; end

    BEARER_PREFIX = "Bearer"

    def initialize(bearer_header)
      # ここでチェックしたいのは 文字列があるか "" or nilではないか
      raise ArgumentError, "bearer_header is required" if bearer_header.blank?
      @bearer_header = bearer_header
    end

    def self.extract(bearer_header)
      new(bearer_header).extract
    end

    def extract
      parts = split_header
      validate_format(parts)
      parts.last
    end

    private

    attr_reader :bearer_header

    def split_header
      bearer_header.split(" ")
    end

    def validate_format(parts)
      return if parts.first.start_with?(BEARER_PREFIX) && parts.size == 2
      raise InvalidFormatError, 'Authorization header must start with "Bearer " and have exactly 2 parts'
    end
  end
```

**現状:**
- `InvalidFormatError`という独自のエラークラスを定義している
- 認証エラー（401）として扱うべきだが、現在は`StandardError`として処理される

### 6. Users::SetupService

```1:35:app/services/users/setup_service.rb
module Users
  class SetupService
    def self.call(auth_header:)
      new.call(auth_header: auth_header)
    end

    def call(auth_header:)
      token = extract_token(auth_header)
      user_info = fetch_user_info(token)
      # user_infoにsub, name, email, pictureが含まれている前提。
      setup_user(user_info)
    end

    private

    def extract_token(auth_header)
      Authentication::BearerTokenExtractor.extract(auth_header)
    end

    def fetch_user_info(token)
      Infra::Http::Client.new.get(
        url: "https://www.googleapis.com/oauth2/v3/userinfo",
        headers: { "Authorization" => "Bearer #{token}" }
      )
    end

    def setup_user(user_info)
      User.find_or_create_by(uid: user_info["sub"]) do |u|
        u.name = user_info["name"]
        u.email = user_info["email"]
        u.image = user_info["picture"]
      end
    end
  end
end
```

**現状:**
- エラーハンドリングが実装されていない
- 各メソッドで発生する例外はそのまま上位に伝播する

## 問題点の整理

### 1. 未定義のエラークラス

**問題:**
- `Infra::Http::Client`で`ClientError`、`ServerError`、`UnknownError`をraiseしているが、これらのクラスが定義されていない
- 実行時に`NameError`が発生する可能性がある

**影響:**
- HTTPクライアントのエラーハンドリングが機能しない
- 外部API呼び出し時のエラーが適切に処理されない

### 2. 不適切なエラーハンドリング

**問題:**
- `ApplicationController`で全てのエラーを500エラーとして返している
- クライアントエラー（400系）とサーバーエラー（500系）の区別がない

**影響:**
- クライアントが適切なエラーハンドリングを行えない
- エラーの種類に応じた適切な対応ができない
- デバッグが困難

**具体例:**
- 認証エラー（401）が500エラーとして返される
- バリデーションエラー（422）が500エラーとして返される
- リソースが見つからない（404）が500エラーとして返される

### 3. エラークラスの階層構造がない

**問題:**
- 各サービスで独自のエラークラスを定義しているが、統一された階層構造がない
- `StandardError`を直接継承しているため、エラーの種類を判別しにくい

**影響:**
- エラーハンドリングが複雑になる
- エラーの種類に応じた適切な処理ができない

**現在のエラークラス:**
- `Infra::Http::Response::Error < StandardError`
- `Authentication::BearerTokenExtractor::Error < StandardError`
- `Authentication::BearerTokenExtractor::InvalidFormatError < Error`

### 4. エラーメッセージの形式が統一されていない

**問題:**
- エラーメッセージの形式が統一されていない
- エラーの種類によってメッセージ形式が異なる

**現状:**
- `ApplicationController`: `{ error: "An unexpected error occurred" }`
- `Infra::Http::Client`: `response.body`をそのままエラーメッセージとして使用
- `Authentication::BearerTokenExtractor`: カスタムメッセージ

**影響:**
- フロントエンドでのエラーハンドリングが複雑になる
- エラーメッセージの形式が予測できない

### 5. エラーログの詳細度が不十分

**問題:**
- エラーログにはメッセージとバックトレースのみが記録されている
- エラーの種類やコンテキスト情報が不足している

**現状:**
```ruby
Rails.logger.error "Standard error occurred: #{error.message}\n#{error.backtrace.join("\n")}"
```

**影響:**
- エラーの原因を特定しにくい
- デバッグが困難

## エラーフロー分析

### 現在のエラーフロー

1. **サービス層でエラー発生**
   - `Users::SetupService` → `Authentication::BearerTokenExtractor::InvalidFormatError`
   - `Users::SetupService` → `Infra::Http::Client` → `ClientError`（未定義）
   - `Users::SetupService` → `Infra::Http::Response::Error`

2. **コントローラー層でエラー処理**
   - `UsersController` → エラーハンドリングなし
   - `ApplicationController::handle_standard_error` → 全て500エラーとして返す

3. **クライアントへのレスポンス**
   - 全て `{ error: "An unexpected error occurred" }` + 500ステータス

### 問題のあるエラーフロー例

**ケース1: 認証ヘッダーが不正な場合**
1. `BearerTokenExtractor::InvalidFormatError`が発生
2. `ApplicationController::handle_standard_error`でキャッチ
3. 500エラーとして返される（本来は401エラー）

**ケース2: 外部APIが400エラーを返した場合**
1. `Infra::Http::Client`で`ClientError`をraiseしようとする
2. `ClientError`が未定義のため`NameError`が発生
3. `ApplicationController::handle_standard_error`でキャッチ
4. 500エラーとして返される（本来は400エラー）

## まとめ

### 主要な問題

1. **未定義のエラークラス**: `ClientError`、`ServerError`、`UnknownError`が定義されていない
2. **不適切なHTTPステータスコード**: 全てのエラーが500エラーとして返される
3. **エラークラスの階層構造がない**: 統一されたエラークラス階層がない
4. **エラーメッセージの形式が統一されていない**: エラーの種類によって形式が異なる
5. **エラーログの詳細度が不十分**: エラーの原因を特定しにくい

### 影響範囲

- **コントローラー層**: エラーハンドリングが不適切
- **サービス層**: エラークラスが未定義または不統一
- **インフラ層**: HTTPクライアントのエラーハンドリングが機能しない
- **認証層**: 認証エラーが適切に処理されない

### 次のステップ

対応方針については別途相談が必要。

