# Skillupia API

## 概要

Skillupia APIは、学習履歴管理システムのバックエンドAPIです。Rails APIモードで構築され、学習記録の管理、ユーザー認証、AI連携機能を提供します。

## 技術スタック

- **Framework**: Ruby on Rails 7.x (API mode)
- **Database**: PostgreSQL 15+
- **Authentication**: AWS Cognito
- **AI Integration**: AWS Bedrock (Claude 3)
- **Containerization**: Docker & Docker Compose
- **Deployment**: Fly.io

## 主要機能

### 学習記録管理
- 学習記録のCRUD操作
- タグ付け機能（手動・AI自動生成）
- 学習時間の記録・集計

### ユーザー管理
- AWS Cognito連携認証
- プロフィール管理
- 学習統計情報

### AI連携
- 学習記録からの自動タグ生成
- 学習内容の振り返り・フィードバック
- 日報の自動生成支援

### バッジシステム
- 学習時間に応じたバッジ付与
- 継続日数に応じたバッジ付与
- 将来的に管理画面での動的バッジ作成

## 環境構築

### 前提条件

- Docker & Docker Compose
- AWS CLI (Bedrock/Cognito連携用)

### セットアップ手順

1. **Docker環境の起動**
   ```bash
   docker-compose up -d
   ```

2. **依存関係のインストール**
   ```bash
   docker-compose exec api bundle install
   ```

3. **環境変数の設定**
   ```bash
   cp .env.example .env
   # .envファイルを編集して必要な環境変数を設定
   ```

4. **データベースのセットアップ**
   ```bash
   docker-compose exec api rails db:create
   docker-compose exec api rails db:migrate
   docker-compose exec api rails db:seed
   ```

5. **サーバーの起動**
   ```bash
   docker-compose up
   ```

### 必要な環境変数

```env
# Database
DATABASE_URL=postgresql://username:password@localhost/skillupia_api_development

# AWS Cognito
AWS_REGION=ap-northeast-1
COGNITO_USER_POOL_ID=your_user_pool_id
COGNITO_CLIENT_ID=your_client_id

# AWS Bedrock
BEDROCK_REGION=ap-northeast-1
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Rails
SECRET_KEY_BASE=your_secret_key_base
```

## API エンドポイント

### 認証
- `POST /auth/login` - ログイン
- `POST /auth/logout` - ログアウト
- `GET /auth/me` - ユーザー情報取得

### 学習記録
- `GET /api/study_records` - 学習記録一覧
- `POST /api/study_records` - 学習記録作成
- `GET /api/study_records/:id` - 学習記録詳細
- `PUT /api/study_records/:id` - 学習記録更新
- `DELETE /api/study_records/:id` - 学習記録削除

### タグ
- `GET /api/tags` - タグ一覧
- `POST /api/tags` - タグ作成
- `POST /api/study_records/:id/generate_tags` - AI自動タグ生成

### 統計・ダッシュボード
- `GET /api/dashboard/stats` - 学習統計
- `GET /api/dashboard/progress` - 進捗情報

### バッジ
- `GET /api/badges` - バッジ一覧
- `GET /api/user_badges` - ユーザーバッジ一覧

## 開発

### テスト実行
```bash
# 全テスト実行
docker-compose exec api rspec

# 特定のテスト実行
docker-compose exec api rspec spec/models/user_spec.rb
```

### コード品質チェック
```bash
# RuboCop実行
docker-compose exec api bundle exec rubocop

# 自動修正
docker-compose exec api bundle exec rubocop -a
```

### データベース操作
```bash
# マイグレーション作成
docker-compose exec api rails generate migration CreateStudyRecords

# シードデータ投入
docker-compose exec api rails db:seed

# コンソール起動
docker-compose exec api rails console
```

## デプロイ

### Fly.io デプロイ

1. **Fly.io CLI インストール**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **アプリケーション初期化**
   ```bash
   fly launch
   ```

3. **データベース作成**
   ```bash
   fly postgres create
   ```

4. **デプロイ**
   ```bash
   fly deploy
   ```

## 関連リポジトリ

- [skillupia_front](../skillupia_front/) - Next.js フロントエンド
- [skillupia_docs](../skillupia_docs/) - プロジェクトドキュメント
