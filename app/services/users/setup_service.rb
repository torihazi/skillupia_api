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
      Infra::Http::Client.get(
        url: 'https://www.googleapis.com/oauth2/v3/userinfo',
        headers: { 'Authorization' => "Bearer #{token}" }
      ).json
    end

    def setup_user(user_info)
      User.find_or_create_by(uid: user_info['sub']) do |u|
        u.name = user_info['name']
        u.email = user_info['email']
        u.image = user_info['picture']
      end
    end
  end
end

