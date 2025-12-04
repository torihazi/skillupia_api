module Authentication
  class TokenExtractor
    class Error < StandardError; end
    class MissingHeaderError < Error; end
    class InvalidFormatError < Error; end
    class MissingTokenError < Error; end

    BEARER_PREFIX = 'Bearer '.freeze

    def self.extract(auth_header)
      new(auth_header).extract
    end

    def initialize(auth_header)
      @auth_header = auth_header
    end

    def extract
      validate_header_presence
      validate_format
      token = extract_token
      validate_token_presence(token)
      token
    end

    private

    attr_reader :auth_header

    def validate_header_presence
      return if auth_header.present?

      raise MissingHeaderError, 'Authorization header is missing'
    end

    def validate_format
      return if auth_header&.start_with?(BEARER_PREFIX)

      raise InvalidFormatError, 'Authorization header must start with "Bearer "'
    end

    def extract_token
      auth_header.split(' ').last
    end

    def validate_token_presence(token)
      return if token.present?

      raise MissingTokenError, 'Token is missing'
    end
  end
end

