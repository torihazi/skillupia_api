# # このクラスがやることは google の userinfoエンドポイントにリクエストしてユーザ情報を取得する
# # それを行う上で何が必要だろうか。
# # endpointは 固定
# # responseの形式はjsonである
# # endpointにリクエストして、responseを取得してそれをsetupに返す？
# # いらないかも setuoに含めてしまって良い。

# module Authentication
#   class UserinfoClient
#     ENDPOINT = 'https://www.googleapis.com/oauth2/v3/userinfo'

#     def self.fetch(token)
#       new(token).fetch
#     end

#     def fetch
#       response = Infra::Http::Client.get(ENDPOINT, headers: { 'Authorization' => "Bearer #{token}" })
#       # ここでresponseをパースしてjsonを返さないといけない
#       # ここでjson parseするのは違う気がする。
#       # json parseするのはもっと下のレイヤーで行うべき
#     end
#   end
# end
