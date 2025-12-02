class UsersController < ApplicationController

  def setup
    # Authorizationヘッダーの存在確認
    auth_header = request.headers['Authorization']
    unless auth_header&.start_with?('Bearer ')
      render json: { error: 'Authorization header is missing or invalid' }, status: :unauthorized
      return
    end

    # Bearerトークンの抽出と形式検証
    token = auth_header.split(' ').last
    if token.blank?
      render json: { error: 'Token is missing' }, status: :unauthorized
      return
    end

    # Google Userinfo Endpointへのリクエスト
    uri = URI.parse('https://openidconnect.googleapis.com/v1/userinfo')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http_request = Net::HTTP::Get.new(uri)
    http_request['Authorization'] = "Bearer #{token}"
    response = http.request(http_request)

    # HTTPレスポンスステータスコードの検証
    unless response.is_a?(Net::HTTPSuccess)
      error_message = case response.code.to_i
                      when 401
                        'Invalid or expired token'
                      when 403
                        'Access forbidden'
                      else
                        'Failed to authenticate with Google'
                      end
      Rails.logger.error "Google API error: #{response.code} - #{response.body}"
      render json: { error: error_message }, status: :unauthorized
      return
    end

    # ユーザー情報の取得
    user_info = JSON.parse(response.body)

    # 必須フィールドの検証
    unless user_info['sub'].present?
      Rails.logger.error "Invalid user info response: #{user_info.inspect}"
      render json: { error: 'Invalid user information received' }, status: :unprocessable_entity
      return
    end

    # Userモデルの取得または作成
    user = User.find_or_create_by(uid: user_info['sub']) do |u|
      u.name = user_info['name']
      u.email = user_info['email']
      u.image = user_info['picture']
    end

    # 既存ユーザーの属性を更新（Google側で変更された可能性があるため）
    if user.persisted?
      user.update(
        name: user_info['name'],
        email: user_info['email'],
        image: user_info['picture']
      )
    end

    render json: user, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parse error: #{e.message}"
    render json: { error: 'Invalid response from authentication service' }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
  end
end
