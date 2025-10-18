FROM ruby:3.2.2

# 必要なパッケージのインストール
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    vim

# 作業ディレクトリの設定
WORKDIR /app

# Gemfileをコピーしてbundle install
COPY Gemfile Gemfile.lock ./
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート8000を公開
EXPOSE 8000

# サーバー起動コマンド
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -p 8000 -b '0.0.0.0'"]