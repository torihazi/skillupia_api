# HTTPクライアントの汎用実装
#
# 【責務】
# - 外部HTTP APIへのリクエスト送信とレスポンス取得
# - HTTP通信の共通処理（SSL設定、タイムアウト、エラーハンドリングなど）
# - ドメイン固有のロジックは含めない（Google::UserinfoClientなどが利用）

require "net/http"
require "uri"

module Infra
  module Http
    class Client
      def get(url:, headers: {})
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http_request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| http_request[key] = value }
        response = http.request(http_request)
        handle_response(Response.new(response))
      end

      def post(url:, headers: {}, body: {})
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http_request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| http_request[key] = value }
        http_request.body = body.to_json
        response = http.request(http_request)
        handle_response(Response.new(response))
      end

      private

      # Responseを使うことでResponse
      # Responseは status, body, headers メソッドを公開している
      # 必要に応じてjsonメソッドを呼び出すことで パースしたjsonを取得できる
      def handle_response(response)
        status = response.status
        case status
        when 200..299
          response
        when 400..499
          raise ClientError, response.body
        when 500..599
          raise ServerError, response.body
        else
          raise UnknownError, response.body
        end
      end
    end
  end
end
