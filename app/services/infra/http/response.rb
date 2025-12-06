module Infra
  module Http
    class Response
      attr_reader :status, :body, :header

      def initialize(net_http_response)
        raise ApplicationError::InternalServerError.new(
          "net_http_response is required",
          context: { method: :initialize }
        ) if net_http_response.nil?

        # 複数のパターンに対応
        @status = extract_status(net_http_response)
        @body = extract_body(net_http_response)
        @header = extract_header(net_http_response)
      end

      def json
        raise ApplicationError::InternalServerError.new(
          "Response status is not 2xx: #{status}",
          context: { status: status, method: :json }
        ) unless success?
        
        return nil if status == 204
        @json ||= JSON.parse(body)
      rescue JSON::ParserError => e
        raise ApplicationError::InternalServerError.new(
          "Failed to parse JSON: #{e.message}",
          context: { parse_error: e.message, method: :json }
        )
      end

      def success?
        status.between?(200, 299)
      end

      private

      def extract_status(response)
        # codeまたはstatusがあるか確認し結果を返す
        if response.respond_to?(:code)
          response.code.to_i
        elsif response.respond_to?(:status)
          response.status.to_i
        else
          raise ApplicationError::InternalServerError.new(
            "response must respond to code or status",
            context: { method: :extract_status }
          )
        end
      end

      def extract_body(response)
        # bodyがあるか確認し結果を返す
        if response.respond_to?(:body)
          response.body
        else
          raise ApplicationError::InternalServerError.new(
            "response must respond to body",
            context: { method: :extract_body }
          )
        end
      end

      def extract_header(response)
        # headersがあるか確認し結果を返す
        if response.respond_to?(:header)
          response.header
        else
          raise ApplicationError::InternalServerError.new(
            "response must respond to header",
            context: { method: :extract_header }
          )
        end
      end
    end
  end
end
