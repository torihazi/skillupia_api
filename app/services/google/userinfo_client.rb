module Google
  class UserinfoClient
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class InvalidResponseError < Error; end
    class NetworkError < Error; end

    USERINFO_ENDPOINT = 'https://openidconnect.googleapis.com/v1/userinfo'.freeze

    def self.fetch(token)
      new.fetch(token)
    end

    def fetch(token)
      response = make_request(token)
      validate_response(response)
      parse_response(response)
    rescue Net::HTTPError, Timeout::Error, SocketError => e
      Rails.logger.error "Network error when fetching userinfo: #{e.message}"
      raise NetworkError, 'Failed to connect to Google API'
    end

    private

    def make_request(token)
      uri = URI.parse(USERINFO_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http_request = Net::HTTP::Get.new(uri)
      http_request['Authorization'] = "Bearer #{token}"
      http.request(http_request)
    end

    def validate_response(response)
      return if response.is_a?(Net::HTTPSuccess)

      error_message = case response.code.to_i
                      when 401
                        'Invalid or expired token'
                      when 403
                        'Access forbidden'
                      else
                        'Failed to authenticate with Google'
                      end
      Rails.logger.error "Google API error: #{response.code} - #{response.body}"
      raise AuthenticationError, error_message
    end

    def parse_response(response)
      user_info = JSON.parse(response.body)
      validate_user_info(user_info)
      user_info
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error: #{e.message}"
      raise InvalidResponseError, 'Invalid response from authentication service'
    end

    def validate_user_info(user_info)
      return if user_info['sub'].present?

      Rails.logger.error "Invalid user info response: #{user_info.inspect}"
      raise InvalidResponseError, 'Invalid user information received'
    end
  end
end

