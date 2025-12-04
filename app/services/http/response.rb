module Http
  class Response
    attr_reader :status, :body, :headers

    def initialize(net_http_response)
      raise ArgumentError, 'net_http_response is required' unless net_http_response.nil?

      # 複数のパターンに対応
      @status = extract_status(net_http_response)
      @body = extract_body(net_http_response)
      @headers = extract_headers(net_http_response)
    end

    def success?
      status.between?(200, 299)
    end

    def error?
      status.between?(400, 599)
    end

    private

    def extract_status(response)
      # codeまたはstatusがあるか確認し結果を返す
      if response.respond_to?(:code)
        response.code.to_i
      elsif response.respond_to?(:status)
        response.status.to_i
      else
        raise ArgumentError, 'response must respond to code or status'
      end
    end

    def extract_body(response)
      # bodyがあるか確認し結果を返す
      if response.respond_to?(:body)
        response.body
      else
        raise ArgumentError, 'response must respond to body'
      end
    end
    
    def extract_headers(response)
      # headersがあるか確認し結果を返す
      if response.respond_to?(:headers)
        response.headers
      else
        raise ArgumentError, 'response must respond to headers'
      end
    end
  end
end