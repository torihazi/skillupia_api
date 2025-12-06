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

      # いらないかも。
      def success?
        status.between?(200, 299)
      end

      # clienterrorだからって特に気にならないからいらないかも
      def client_error?
        status.between?(400, 499)
      end

      # servererrorだからってerrorなったから気になるわけだしいらないかも
      def server_error?
        status.between?(500, 599)
      end

      private

      def extract_status(response)
        # codeまたはstatusがあるか確認し結果を返す
        if response.respond_to?(:code)
          response.code.to_i
        elsif response.respond_to?(:status)
          response.status.to_i
        else
          raise ArgumentError, "response must respond to code or status"
        end
      end

      def extract_body(response)
        # bodyがあるか確認し結果を返す
        if response.respond_to?(:body)
          response.body
        else
          raise ArgumentError, "response must respond to body"
        end
      end

      def extract_header(response)
        # headersがあるか確認し結果を返す
        if response.respond_to?(:header)
          response.header
        else
          raise ArgumentError, "response must respond to header"
        end
      end
    end
  end
end
