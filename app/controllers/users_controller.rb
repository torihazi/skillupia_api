require 'net/http'
require 'uri'
require 'json'

class UsersController < ApplicationController

  def setup
    # requestから Authorization headerを取得
    # Authorization headerから Bearer トークンを取得
    # Bearer トークンを取得して Googleの Userinfo Endpoint にリクエストを送信
    # Userinfo Endpoint からユーザー情報を取得
    # endpoint https://openidconnect.googleapis.com/v1/userinfo
    # 取得したユーザー情報をもとに User モデルを取得もしくは作成
    # 作成した User モデルを返す
    token = request.headers['Authorization'].split(' ').last
    uri = URI.parse('https://openidconnect.googleapis.com/v1/userinfo')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{token}"
    response = http.request(request)
    user_info = JSON.parse(response.body)

    user = User.find_or_create_by(uid: user_info['sub']) do |user|
      user.name = user_info['name']
      user.email = user_info['email']
      user.image = user_info['picture']
    end
    render json: user, status: :ok
  rescue => e
    Rails.logger.error "Error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
end
