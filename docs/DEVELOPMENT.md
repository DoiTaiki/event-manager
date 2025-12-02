# 開発ガイド

## セットアップ

### 前提条件

#### ローカル開発環境

- **VS Code**: Dev Containers 拡張機能がインストールされていること
- **Docker**: Docker Desktop または Docker Engine がインストール・起動されていること
- **Git**: リポジトリのクローンに必要

### クイックスタート（ローカル開発）

#### 方法1：Dev Container を使用（推奨）

このプロジェクトは VS Code の Dev Container 機能を使用して開発環境を提供します。

1. **リポジトリのクローン**

   ```bash
   git clone <repository-url>
   cd event-manager
   ```

2. **VS Code で開く**

   ```bash
   code .
   ```

3. **Dev Container で開く**

   - VS Code のコマンドパレット（`Cmd+Shift+P` / `Ctrl+Shift+P`）を開く
   - 「Dev Containers: Reopen in Container」を選択
   - 初回はコンテナのビルドに時間がかかります

4. **自動セットアップ**

   Dev Container が起動すると、`postCreateCommand` により以下が自動実行されます：

   - 依存関係のインストール（`bundle install`、`npm install`）
   - データベースのセットアップ（`bin/rails db:prepare`）

5. **開発サーバーの起動**

   Dev Container 内のターミナルで以下のコマンドを実行：

   ```bash
   bin/dev
   ```

   アプリケーションは `http://localhost:3000` でアクセスできます。

#### Dev Container の構成

- **サービス**: Rails アプリ、MySQL 8.0、Selenium（システムテスト用）
- **ポート転送**: 3000（Rails）、3306（MySQL）
- **環境変数**: データベース接続情報が自動設定されます
- **機能**: GitHub CLI、Node.js、Docker が利用可能

#### 方法2：ローカル環境で直接実行

Dev Container を使用しない場合：

```bash
# リポジトリのクローン
git clone <repository-url>
cd event-manager

# 依存関係のインストールとセットアップ
bin/setup

# 開発サーバーの起動
bin/dev
```

**注意**: ローカル実行の場合は、Ruby 3.4.7、MySQL 8.0、Node.js 22.21.0 を別途インストールする必要があります。

## 構成

### Ruby version

- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **Node.js**: 22.21.0（ビルド時）

`.ruby-version` ファイルでバージョンが管理されています。

### System dependencies

#### ローカル開発環境（Dev Container）

- **MySQL**: 8.0（Dev Container で自動セットアップ）
- **Node.js**: 22.21.0（Dev Container の機能として提供）
- **Selenium**: システムテスト用（Dev Container で自動セットアップ）
- **Docker**: Dev Container の実行に必要

### Configuration

アプリケーションにより使用される環境変数

#### 必須環境変数

- `RAILS_MASTER_KEY`: Rails のマスターキー（`config/master.key` から取得）
- `DB_HOST`: データベースホスト
- `DB_NAME`: データベース名
- `DB_USERNAME`: データベースユーザー名
- `DB_PASSWORD`: データベースパスワード

#### Dev Container 環境

Dev Container では、以下の環境変数が自動設定されます：
- `DB_HOST`: mysql
- `DB_USERNAME`: root
- `DB_PASSWORD`: password
- `DB_PORT`: 3306
- `CAPYBARA_SERVER_PORT`: 45678
- `SELENIUM_HOST`: selenium

#### 本番環境（AWS）

本番環境では、これらの値は AWS Secrets Manager から自動的に取得されます：
- `RAILS_MASTER_KEY`: Secrets Manager の `prod/{AppName}/rails_master_key` から取得
- `DB_USERNAME`, `DB_PASSWORD`: Aurora MySQL のマスターユーザーシークレットから取得

詳細は [デプロイ手順](./DEPLOYMENT.md) を参照してください。

## Database creation

データベースの作成とマイグレーション：

```bash
# 開発環境（Dev Container 内）
bin/rails db:create
bin/rails db:migrate

# または、セットアップスクリプトを使用（推奨）
bin/setup
```

Dev Container の `postCreateCommand` により、初回起動時に自動的にデータベースがセットアップされます。

本番環境では、CloudFormation テンプレートが Aurora MySQL クラスターを作成し、ECS タスク起動時に自動的にマイグレーションが実行されます。

詳細は [デプロイ手順](./DEPLOYMENT.md) を参照してください。

## Database initialization

初期データの投入：

```bash
bin/rails db:seed
```

`db/seeds.rb` が実行され、`db/seeds/events.json` からイベントデータが読み込まれます。

## How to run the test suite

### 基本的なテスト実行

```bash
# システムテストを除くすべてのテストを実行（コントローラー、モデルなど）
bin/rails test

# システムテストのみ実行
bin/rails test:system

# テストデータベースの準備
bin/rails db:test:prepare
```

### CI パイプラインの実行

完全な CI パイプライン（リンター、セキュリティチェック、テスト）を実行：

```bash
bin/ci
```

このコマンドは以下を実行します：
- セットアップ（`bin/setup --skip-server`）
- Ruby スタイルチェック（RuboCop）
- セキュリティ監査（bundler-audit、npm audit、Brakeman）
- テスト（Rails テスト、システムテスト、シードテスト）

### テスト環境

Dev Container では以下が自動セットアップされます：
- **データベース**: MySQL 8.0（テスト用）
- **ブラウザテスト**: Selenium + Chrome（システムテスト用）

## Services

このアプリケーションは以下の Rails 8 のデータベースバックエンドサービスを使用しています：

- **Solid Cache**: データベースバックエンドのキャッシュ（`db/cache_migrate`）
- **Solid Queue**: データベースバックエンドのジョブキュー（`db/queue_migrate`）
- **Solid Cable**: データベースバックエンドの Action Cable（`db/cable_migrate`）

これらはすべて同じデータベース内で異なるテーブルセットとして管理されます。
