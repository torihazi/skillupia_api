module Authentication
  # [責務]
  # 認証ヘッダーから トークンを抽出する
  # それを行う上で何が必要だろうか。
  # bearer ヘッダーから トークンを抽出する
  # まずものがあるか
  # 正しい形式かどうか
  # あれば空白で分割して、後ろを取得
  # 取得結果を返す
  # 外部からsetできなくて良いので隠蔽する
  # ただextractorは取り出す人なので、所有物については公開するというのはおかしい
  # つまりextractorは取り出して、結果を返すだけの人。
  # インスタンス化はする必要がない。その機能を使いたいだけ。
  # ただ内部では状態を保持しておくと引数が減らせるため、インスタンス化しておく。
  # 内部で auth_headerを保持してどこからでもみれるようにしたいので attr_readerで公開するが、
  # このクラス内に限って参照できれば良いので private attr_readerで公開する

  class BearerTokenExtractor
    BEARER_PREFIX = "Bearer"

    def initialize(bearer_header)
      # ここでチェックしたいのは 文字列があるか "" or nilではないか
      raise ApplicationError::BadRequestError.new(
        "bearer_header is required",
      ) if bearer_header.blank?
      @bearer_header = bearer_header
    end

    def self.extract(bearer_header)
      new(bearer_header).extract
    end

    def extract
      parts = split_header
      validate_format(parts)
      parts.last
    end

    private

    attr_reader :bearer_header

    def split_header
      bearer_header.split(" ")
    end

    def validate_format(parts)
      return if parts.first.start_with?(BEARER_PREFIX) && parts.size == 2
      raise ApplicationError::UnauthorizedError.new(
        'Authorization header must start with "Bearer " and have exactly 2 parts',
      )
    end
  end
end
