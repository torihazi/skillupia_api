# 認証の流れ

```mermaid
sequenceDiagram
    actor User as ユーザー
    participant Next as Next.js<br/>(Route Handler)
    participant Rails as Rails API<br/>(OmniAuth)
    participant Google as Google OAuth

    User->>Next: ログインボタンをクリック
    Next->>Rails: GET /auth/google_oauth2
    Rails->>Google: 認証リクエスト<br/>(client_id, redirect_uri, scope)
    Google-->>User: Googleログイン画面表示
    User->>Google: Google認証情報を入力
    Google->>Google: 認証処理
    Google->>Rails: GET /auth/google_oauth2/callback<br/>(code)
    Rails->>Google: アクセストークン要求<br/>(code, client_secret)
    Google-->>Rails: アクセストークン返却
    Rails->>Google: ユーザー情報要求<br/>(access_token)
    Google-->>Rails: ユーザー情報返却
    Rails->>Rails: ユーザー作成/更新<br/>セッション生成
    Rails-->>Next: リダイレクト + セッションCookie/JWT
    Next->>Rails: GET /api/user<br/>(Cookie/JWT)
    Rails-->>Next: ユーザー情報返却
    Next-->>User: ログイン完了<br/>ダッシュボード表示

```

# やるべきこと

Rails 側でやるべきなのは
omniauth からどんな情報が返ってくるか

sessions#create で以下
request.env['omniauth.auth']の中身を調べればいい
uid UserIdentifier は Idp (Identity Provider)内でユーザを一位に識別する識別し。
複数の idp に対応する場合は provider と uid の組み合わせで一位性を保証する必要がある。

uid: "uid"
info => {
"name" => "John Smith",
"email" => "john@example.com",
"image" => "https://lh4.googleusercontent.com/photo.jpg",
}
"credentials" => {
"token" => "TOKEN",
"refresh_token" => "REFRESH_TOKEN",
"expires_at" => 1496120719,
"expires" => true
},

これらを取得する必要がある。

- User テーブルの作成
- uid, name, email, image で良いか
- 全て null false で良い

model ファイルは作成、全て validates の present をつけた。

情報としてはめっちゃ良いけど next.js から rails の omniauth endpoint 叩くのだるそうだったから omniauth 断念

Next.js 側で nextauth.js やることにした。

結局またこれか
