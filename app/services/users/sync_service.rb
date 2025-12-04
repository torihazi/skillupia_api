module Users
  class SyncService
    class Error < StandardError; end
    class InvalidUserInfoError < Error; end

    REQUIRED_FIELDS = %w[sub name email picture].freeze

    def self.sync(user_info)
      new.sync(user_info)
    end

    def sync(user_info)
      validate_user_info(user_info)
      user = find_or_create_user(user_info)
      update_user_attributes(user, user_info)
      user
    end

    private

    def validate_user_info(user_info)
      missing_fields = REQUIRED_FIELDS.reject { |field| user_info[field].present? }
      return if missing_fields.empty?

      raise InvalidUserInfoError, "Missing required fields: #{missing_fields.join(', ')}"
    end

    def find_or_create_user(user_info)
      User.find_or_create_by(uid: user_info['sub']) do |u|
        u.name = user_info['name']
        u.email = user_info['email']
        u.image = user_info['picture']
      end
    end

    def update_user_attributes(user, user_info)
      return unless user.persisted?

      user.update(
        name: user_info['name'],
        email: user_info['email'],
        image: user_info['picture']
      )
    end
  end
end

