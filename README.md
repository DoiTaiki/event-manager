# Event Manager

Rails アプリケーションを AWS 上で実行するためのイベント管理システムです。

## プロジェクトについて

このプロジェクトは、Rails と React を用いた開発方法のキャッチアップを目的として作成されました。Rails 7 と React 18 を使用した CRUD アプリケーションの構築方法を学習するための実装です。

本プロジェクトは、[TechRacho の「Rails 7とReactによるCRUDアプリ作成チュートリアル」](https://techracho.bpsinc.jp/hachi8833/2022_05_26/118202) を参考にしています。このチュートリアルでは、Ruby on Rails で JSON API を構築し、その API と通信する React フロントエンドを実装する方法が解説されています。

### 技術スタック

- **バックエンド**: Ruby on Rails 8.1.1
- **フロントエンド**: React 19.2.0
- **ルーティング**: React Router DOM 6.30.2
- **日付選択**: Pikaday 1.8.2
- **通知**: React Toastify 11.0.5
- **バンドラー**: esbuild 0.27.0
- **データベース**: MySQL 8.0（開発環境）、Aurora MySQL Serverless v2（本番環境）

### 主な機能

- イベントの CRUD 操作（作成・読み取り・更新・削除）
- 日付選択機能（Pikaday）
- イベントの絞り込み機能
- Flash メッセージ表示（React Toastify）

## アーキテクチャ概要

このアプリケーションは AWS CloudFormation テンプレートを使用して、以下の AWS サービスで構成されています：

```
┌──────────┐
│  ユーザー  │
└────┬─────┘
     │ HTTPS
     ▼
┌─────────────┐
│  Route 53   │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│     ALB     │─────▶│ ECS Service │─────▶│ Aurora    │
│  (HTTPS)    │      │  (Fargate)  │      │   MySQL     │
└─────────────┘      └─────────────┘      └─────────────┘
       │                     │                     │
       │                     │                     │
       ▼                     ▼                     ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ S3 (Logs)   │      │     ECR     │      │  Secrets    │
│             │      │  (Images)    │      │  Manager    │
└─────────────┘      └─────────────┘      └─────────────┘

【CI/CD】
GitHub → CodePipeline → CodeBuild → ECR → ECS
```

### 主要コンポーネント

- **ネットワーク**: VPC、パブリック/プライベートサブネット（マルチAZ）
- **コンピューティング**: ECS Fargate で Rails アプリケーションを実行
- **ロードバランサー**: Application Load Balancer（HTTPS対応）
- **データベース**: Aurora MySQL Serverless v2（マルチAZ構成）
- **CI/CD**: CodePipeline + CodeBuild による自動デプロイ
- **ストレージ**: ECR（Docker イメージ）、S3（ログ・アーティファクト）
- **セキュリティ**: Secrets Manager、VPC エンドポイント、セキュリティグループ

詳細なアーキテクチャ図については、[aws-architecture-diagram.md](./aws-architecture-diagram.md) を参照してください。

## セットアップ

### 前提条件

#### ローカル開発環境

- **VS Code**: Dev Containers 拡張機能がインストールされていること
- **Docker**: Docker Desktop または Docker Engine がインストール・起動されていること
- **Git**: リポジトリのクローンに必要

#### AWS デプロイ

- **AWS CLI**: インストール・設定済み
- **CloudFormation テンプレート**: `rails-ecs-codepipeline-cf.yaml` のパラメータを準備
- **CodeStar Connection**: GitHub アカウントとの接続を事前に作成

### クイックスタート（ローカル開発）

#### Dev Container を使用（推奨）

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

   Dev Container 内のターミナルで：

   ```bash
   bin/dev
   ```

   アプリケーションは `http://localhost:3000` でアクセスできます。

#### Dev Container の構成

- **サービス**: Rails アプリ、MySQL 8.0、Selenium（システムテスト用）
- **ポート転送**: 3000（Rails）、3306（MySQL）
- **環境変数**: データベース接続情報が自動設定されます
- **機能**: GitHub CLI、Node.js、Docker が利用可能

#### 方法2: ローカル環境で直接実行

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

#### 本番環境（AWS）

- **Aurora MySQL**: Serverless v2（マルチAZ構成）
- **ECS Fargate**: コンテナ実行環境
- **Application Load Balancer**: ロードバランサー

### Configuration

アプリケーションは環境変数で設定されます：

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

### Database creation

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

### Database initialization

初期データの投入：

```bash
bin/rails db:seed
```

`db/seeds.rb` が実行され、`db/seeds/events.json` からイベントデータが読み込まれます。

### How to run the test suite

#### 基本的なテスト実行

```bash
# システムテストを除くすべてのテストを実行（コントローラー、モデルなど）
bin/rails test

# システムテストのみ実行
bin/rails test:system

# テストデータベースの準備
bin/rails db:test:prepare
```

#### CI パイプラインの実行

完全な CI パイプライン（リンター、セキュリティチェック、テスト）を実行：

```bash
bin/ci
```

このコマンドは以下を実行します：
- セットアップ（`bin/setup --skip-server`）
- Ruby スタイルチェック（RuboCop）
- セキュリティ監査（bundler-audit、npm audit、Brakeman）
- テスト（Rails テスト、システムテスト、シードテスト）

#### テスト環境

Dev Container では以下が自動セットアップされます：
- **データベース**: MySQL 8.0（テスト用）
- **ブラウザテスト**: Selenium + Chrome（システムテスト用）

### Services

このアプリケーションは以下の Rails 8 のデータベースバックエンドサービスを使用しています：

- **Solid Cache**: データベースバックエンドのキャッシュ（`db/cache_migrate`）
- **Solid Queue**: データベースバックエンドのジョブキュー（`db/queue_migrate`）
- **Solid Cable**: データベースバックエンドの Action Cable（`db/cable_migrate`）

これらはすべて同じデータベース内で異なるテーブルセットとして管理されます。

### Deployment instructions

#### AWS へのデプロイ

1. **CloudFormation テンプレートの準備**

   `rails-ecs-codepipeline-cf.yaml` のパラメータを確認・設定：
   - `AppName`: アプリケーション名（デフォルト: EventManager）
   - `RailsMasterKey`: `config/master.key` の値
   - `DatabaseUsername`: データベースユーザー名（デフォルト: root）
   - `DomainName`: ドメイン名（例: example.com）
   - `SubdomainName`: サブドメイン名（例: www.example.com）
   - `GitHubRepo`: GitHub リポジトリ（例: owner/repo）
   - `GitHubBranch`: 監視するブランチ（デフォルト: main）
   - `CodeStarConnectionArn`: CodeStar Connections の ARN

2. **CodeStar Connection の作成**

   AWS コンソールで CodeStar Connections を作成し、GitHub アカウントと接続します。

3. **CloudFormation スタックの作成**

   ```bash
   aws cloudformation create-stack \
     --stack-name event-manager \
     --template-body file://rails-ecs-codepipeline-cf.yaml \
     --parameters ParameterKey=AppName,ParameterValue=EventManager \
                  ParameterKey=RailsMasterKey,ParameterValue=your-master-key \
                  ParameterKey=DomainName,ParameterValue=example.com \
                  ParameterKey=SubdomainName,ParameterValue=www.example.com \
                  ParameterKey=GitHubRepo,ParameterValue=owner/repo \
                  ParameterKey=CodeStarConnectionArn,ParameterValue=arn:aws:codestar-connections:...
     --capabilities CAPABILITY_NAMED_IAM
   ```

4. **Route 53 ネームサーバーの設定**

   スタック作成後、出力された Route 53 ネームサーバーをドメインレジストラに設定します。

5. **初回デプロイ**

   - `ECRImageExists` パラメータを `no` に設定してスタックを作成
   - CodePipeline が自動的にトリガーされ、Docker イメージがビルド・プッシュされます
   - イメージが ECR にプッシュされたら、`ECRImageExists` を `yes` に更新して ECS サービスを有効化

#### デプロイ後の確認

- **アプリケーション URL**: CloudFormation スタックの出力から確認
- **CodePipeline**: AWS コンソールでパイプラインの状態を確認
- **ECS サービス**: ECS コンソールでタスクの状態を確認
- **ログ**: CloudWatch Logs で `/ecs/{AppName}` ロググループを確認
