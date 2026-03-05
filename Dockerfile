# =========================================
# ステージ 1: React.js アプリケーションのビルド
# =========================================

# ビルド用の軽量 Node.js イメージを使用（ARG でカスタマイズ可能）
FROM dhi.io/node:25-debian13-sfw-ent-dev AS builder

# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# Docker のキャッシング機構を活用するため、最初にパッケージ関連ファイルをコピー
COPY package.json package-lock.json* ./

# プロジェクト依存関係をインストール（npm ci を使用して再現可能なインストールを保証）
RUN --mount=type=cache,target=/root/.npm npm ci

# アプリケーション ソースコードの残りをコンテナにコピー
COPY . .

# React.js アプリケーションをビルド（/app/dist に出力）
RUN npm run build

# =========================================
# ステージ 2: 静的ファイルを提供するための Nginx を準備
# =========================================

FROM docker pull dhi.io/nginx:1-debian13-dev AS runner

# カスタム Nginx 設定をコピー
COPY nginx.conf /etc/nginx/nginx.conf

# ビルド ステージから静的ビルド出力を、Nginx のデフォルト HTML サービス ディレクトリにコピー
COPY --chown=nginx:nginx --from=builder /app/dist /usr/share/nginx/html

# セキュリティ ベストプラクティスのため、非ルート ユーザーを使用
USER nginx

# HTTP トラフィックを許可するためにポート 8080 を公開
# 注：デフォルト NGINX コンテナはポート 80 ではなくポート 8080 でリッスン 
EXPOSE 8080

# カスタム設定で Nginx を直接起動
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf"]
CMD ["-g", "daemon off;"]