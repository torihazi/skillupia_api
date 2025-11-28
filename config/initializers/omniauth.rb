# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, 
    Rails.application.config.google_client_id, 
    Rails.application.config.google_client_secret,
    {
      scope: "email, profile",
      prompt: "select_account"
    }
end