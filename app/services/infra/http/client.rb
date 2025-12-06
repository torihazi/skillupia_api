# HTTPクライアントの汎用実装
#
# 【責務】
# - 外部HTTP APIへのリクエスト送信とレスポンス取得
# - HTTP通信の共通処理（SSL設定、タイムアウト、エラーハンドリングなど）
# - ドメイン固有のロジックは含めない（Google::UserinfoClientなどが利用）
#
# 【設計方針】
#
# 1. インターフェース設計
#    - メソッド: get(url, headers: {}) -> Responseオブジェクト
#    - 将来的に post, put, delete なども追加可能な設計
#    - Responseオブジェクトは status_code, body, headers などを提供
#
# 2. エラーハンドリング
#    - カスタムエラークラスを定義（NetworkError, TimeoutError, HttpError など）
#    - HTTPステータスコードに応じたエラーは呼び出し側で判断（4xx, 5xxなど）
#    - ネットワークレベルのエラー（接続失敗、タイムアウト）はここで捕捉
#
# 3. 設定可能な項目
#    - タイムアウト（read_timeout, open_timeout）
#    - SSL設定（use_ssl, verify_mode）
#    - リトライロジック（必要に応じて）
#    - デフォルトヘッダー（User-Agentなど）
#
# 4. 依存性注入
#    - コンストラクタで設定を受け取る設計
#    - テスト時にモック/スタブに差し替え可能にする
#    - クラスメソッドとインスタンスメソッドの両方を提供（使いやすさ重視）
#
# 5. 使用例（想定）
#    client = HttpClient.new(timeout: 5)
#    response = client.get('https://api.example.com/data', headers: { 'Authorization' => 'Bearer token' })
#    if response.success?
#      data = JSON.parse(response.body)
#    end
#
# 6. Google::UserinfoClient での利用イメージ
#    - Google::UserinfoClient は HttpClient を内部で使用
#    - Google固有のエンドポイントやレスポンス処理は Google::UserinfoClient が担当
#    - HTTP通信の詳細は HttpClient に委譲
#
# 7. テスト容易性
#    - 外部依存（Net::HTTP）を抽象化することで、テスト時にモック可能
#    - VCR や WebMock などのgemと組み合わせやすい設計
#
# 【実装時の注意点】
# - Net::HTTP のラッパーとして実装
# - レスポンスオブジェクトは Net::HTTPResponse をラップした独自クラスでも可
# - ログ出力は必要最小限に（機密情報を含む可能性があるため）
# - パフォーマンスを考慮（接続プールなどは必要に応じて）

require 'net/http'
require 'uri'
require 'json'

module Infra
  module Http
    # urlを渡せば、httpリクエストを送信して、Responseオブジェクトを返す
    class Client
      def get(url, headers: {})
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http_request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| http_request[key] = value }
        response = http.request(http_request)
        Response.new(response)
      end

      def post(url, headers: {}, body: {})
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http_request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| http_request[key] = value }
        http_request.body = body.to_json
        response = http.request(http_request)
        Response.new(response)
      end
    end
  end
end
