module Users
  class SetupService
    class Result
      attr_reader :user, :error, :status

      def initialize(user: nil, error: nil, status: :ok)
        @user = user
        @error = error
        @status = status
      end

      def success?
        error.nil?
      end

      def failure?
        !success?
      end
    end

    def self.call(auth_header:)
      new.call(auth_header: auth_header)
    end

    def call(auth_header:)
      token = extract_token(auth_header)
      user_info = fetch_user_info(token)
      user = sync_user(user_info)
      Result.new(user: user)
    rescue Authentication::TokenExtractor::Error => e
      Result.new(error: e.message, status: :unauthorized)
    rescue Google::UserinfoClient::AuthenticationError => e
      Result.new(error: e.message, status: :unauthorized)
    rescue Google::UserinfoClient::InvalidResponseError, Users::SyncService::InvalidUserInfoError => e
      Result.new(error: e.message, status: :unprocessable_entity)
    rescue Google::UserinfoClient::NetworkError => e
      Rails.logger.error "Network error in UserSetupService: #{e.message}"
      Result.new(error: 'Service temporarily unavailable', status: :service_unavailable)
    rescue StandardError => e
      Rails.logger.error "Unexpected error in UserSetupService: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
      Result.new(error: 'An unexpected error occurred', status: :internal_server_error)
    end

    private

    def extract_token(auth_header)
      Authentication::TokenExtractor.extract(auth_header)
    end

    def fetch_user_info(token)
      Google::UserinfoClient.fetch(token)
    end

    def sync_user(user_info)
      Users::SyncService.sync(user_info)
    end
  end
end

