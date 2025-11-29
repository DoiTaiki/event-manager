# Event Manager

Rails アプリケーションを AWS 上で実行するためのイベント管理システムです。

## プロジェクトについて

このプロジェクトは、Rails と React を用いた開発方法のキャッチアップを目的として作成されました。Rails 8 と React 19 を使用した CRUD アプリケーションの構築方法を学習するための実装です。

本プロジェクトの主な特徴は、アプリケーション機能だけでなく、CloudFormation による AWS リソース一式の自動構築に注力している点です。単一テンプレート内でのリソース定義整理や依存関係管理まで含めた、実践的な IaC（Infrastructure as Code）の実装となっています。

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
- **コンピューティング**: ECS Fargate で Rails アプリケーションを実行（デフォルトで2タスク、マルチAZ構成）
- **ロードバランサー**: Application Load Balancer（HTTPS対応）
- **データベース**: Aurora MySQL Serverless v2（マルチAZ構成、約12〜13分の非アクティブ期間で自動ポーズし、復帰は約15秒）
- **データベース監視**: CloudWatch Database Insights(Standard) によるパフォーマンス監視
- **CI/CD**: CodePipeline + CodeBuild による自動デプロイ
- **ストレージ**: ECR（Docker イメージ）、S3（ログ・アーティファクト）
- **セキュリティ**: Secrets Manager、VPC エンドポイント、セキュリティグループ
- **運用**: ECS Exec（任意）でタスク内コンテナへ SSM セッション接続可能

### アーキテクチャ図

AWS アーキテクチャの詳細な図を以下の形式で提供しています：

![AWSアーキテクチャ図](./aws-architecture-diagram.svg)

**図の内容**: VPC、サブネット、ECS、Aurora、CI/CD パイプライン、Route 53、ALB などの詳細な構成

**ファイル形式**:
- **SVG形式（画像表示用）**: [`aws-architecture-diagram.svg`](./aws-architecture-diagram.svg) - GitHub上で画像として表示されます
- **Draw.io形式（編集用）**: [`aws-architecture-diagram.drawio`](./aws-architecture-diagram.drawio) - 図の編集に使用します
- **Markdown形式（詳細説明）**: [`aws-architecture-diagram.md`](./aws-architecture-diagram.md) - 各コンポーネントの詳細な説明

**図の閲覧・編集方法**:
- **GitHub**: リポジトリにプッシュすると、GitHub上で直接図を表示・編集できます
- **Draw.io オンラインエディタ**: [app.diagrams.net](https://app.diagrams.net/) でファイルを開いて編集可能
- **VS Code**: [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) 拡張機能をインストールすると、VS Code内で直接編集できます

## セットアップ

### 前提条件

#### ローカル開発環境

- **VS Code**: Dev Containers 拡張機能がインストールされていること
- **Docker**: Docker Desktop または Docker Engine がインストール・起動されていること
- **Git**: リポジトリのクローンに必要

#### AWS デプロイ

- **AWS CLI**: インストール・設定済み
- **ドメイン**: Route 53 でホストゾーンを作成するか、既存のドメインを Route 53 に移管済みであること
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

#### 本番環境（AWS）

- **Aurora MySQL**: Serverless v2（マルチAZ構成）
- **ECS Fargate**: コンテナ実行環境
- **Application Load Balancer**: ロードバランサー

Aurora Serverless v2 は最小 0 ACU で構成しており、設定上は 300 秒（5 分）間リクエストが無い場合に自動ポーズします。ただし、実際には内部処理の完了を待つため、約 12〜13 分でポーズされます。アクセスが再開されると、通常は 15 秒程度で自動復帰します（24 時間以上ポーズされた場合は 30 秒以上かかることがあります）。

この挙動により、検証環境やトラフィックの少ない時間帯のコスト最適化に役立ちます。

実際のポーズ待機が長めになる主な要因：

- Aurora 内部プロセス（ストレージ同期、バックグラウンドタスク、トランザクションログ書き込み、ヘルスチェック）の完了待機
- マルチ AZ（Writer/Reader）間でのポーズ順序と状態同期（Reader → Writer の順にポーズ）
- データ整合性や自動バックアップとの競合回避を目的とした安全マージン

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

**重要**: AWS にデプロイする際には、予めドメインを登録しておく必要があります。Route 53 でホストゾーンを作成するか、既存のドメインを Route 53 に移管してください。

1. **CloudFormation テンプレートの準備**

   `rails-ecs-codepipeline-cf.yaml` のパラメータを確認・設定：
   - `AppName`: アプリケーション名（デフォルト: EventManager）
   - `RailsMasterKey`: `config/master.key` の値
   - `DatabaseUsername`: データベースユーザー名（デフォルト: root）
   - `DatabaseSnapshotIdentifier`: 復元したいスナップショット ARN（新規作成なら空文字）
   - `UseLatestDatabaseSnapshot`: 最新の手動スナップショットを自動的に使用するか（yes/no）
   - `CodePipelineArtifactsBucketName`: CodePipeline アーティファクト用 S3 バケットのベース名
   - `ECRRepositoryName`: Docker イメージを push する ECR リポジトリ名
   - `AccessLogsBucketExists`: ALB アクセスログ用の既存バケットを使用する場合は `yes`
   - `ECRImageExists`: 既存の ECR イメージを使用する場合は `yes`
   - `DomainName`: ドメイン名（例: example.com）
   - `SubdomainName`: サブドメイン名（例: www.example.com）
   - `GitHubRepo`: GitHub リポジトリ（例: owner/repo）
   - `GitHubBranch`: 監視するブランチ（デフォルト: main）
   - `CodeStarConnectionArn`: CodeStar Connections の ARN
   - `EnableEcsExec`: ECS Exec（SSM Session Manager）を有効にするか（yes/no、デフォルト: no）

2. **CodeStar Connection の作成**

   AWS コンソールで CodeStar Connections を作成し、GitHub アカウントと接続します。

3. **CloudFormation スタックの作成**

   テンプレートは 51,200 バイトのサイズ制限を超えるため、`--template-body` ではなく S3 へアップロードして `--template-url` で参照する必要があります。

   **既存のS3バケットを確認する場合**:

   ```bash
   # すべてのS3バケット一覧を表示
   aws s3 ls

   # 特定のリージョンのバケット一覧を表示
   aws s3 ls --region ap-northeast-1
   ```

   **テンプレートをS3にアップロード**:

   ```bash
   aws s3 cp rails-ecs-codepipeline-cf.yaml s3://your-template-bucket/cf/rails-ecs-codepipeline-cf.yaml
   ```

   ```bash
   aws cloudformation create-stack \
     --stack-name event-manager \
     --template-url https://your-template-bucket.s3.amazonaws.com/cf/rails-ecs-codepipeline-cf.yaml \
     --parameters ParameterKey=AppName,ParameterValue=EventManager \
                  ParameterKey=RailsMasterKey,ParameterValue=your-master-key \
                  ParameterKey=DatabaseUsername,ParameterValue=root \
                  ParameterKey=DatabaseSnapshotIdentifier,ParameterValue='' \
                  ParameterKey=UseLatestDatabaseSnapshot,ParameterValue=no \
                  ParameterKey=CodePipelineArtifactsBucketName,ParameterValue=codepipeline-artifacts \
                  ParameterKey=ECRRepositoryName,ParameterValue=event-manager-repo \
                  ParameterKey=AccessLogsBucketExists,ParameterValue=no \
                  ParameterKey=ECRImageExists,ParameterValue=no \
                  ParameterKey=DomainName,ParameterValue=example.com \
                  ParameterKey=SubdomainName,ParameterValue=www.example.com \
                  ParameterKey=GitHubRepo,ParameterValue=owner/repo \
                  ParameterKey=GitHubBranch,ParameterValue=main \
                  ParameterKey=CodeStarConnectionArn,ParameterValue=arn:aws:codestar-connections:... \
                  ParameterKey=EnableEcsExec,ParameterValue=no \
     --capabilities CAPABILITY_NAMED_IAM
   ```

   **注意**: スタックの作成完了まで通常20〜30分かかります。VPC、サブネット、Aurora、ECS、ALB、Route 53、ACM証明書など多数のリソースを作成するため、時間がかかります。

   **デプロイの進捗確認**:

   ```bash
   aws cloudformation describe-stacks \
     --stack-name event-manager \
     --query "Stacks[0].StackStatus" \
     --output text
   ```

4. **Route 53 ネームサーバーの設定**

   スタック作成後、出力された Route 53 ネームサーバーをドメインレジストラに設定します。

   **自動設定**: 同一アカウント内で Route 53 Domains に登録されたドメインを使用しており、テンプレートに含まれる `NameserverUpdateFunction` が `route53domains:UpdateDomainNameservers` を実行できる条件を満たす場合は、自動で NS 同期が行われます。

   **手動設定**: それ以外（外部レジストラや別アカウントのドメイン）では、手動でネームサーバーを差し替えてください。

5. **初回デプロイ**

   - `ECRImageExists` パラメータを `no` に設定してスタックを作成
   - CodePipeline が自動的にトリガーされ、Docker イメージがビルド・プッシュされます
   - イメージが ECR にプッシュされたら、`ECRImageExists` を `yes` に更新して ECS サービスを有効化
   - イメージ push の確認:

     ```bash
     aws ecr describe-images \
       --repository-name event-manager-repo \
       --query "imageDetails[].imageTags" \
       --output table
     ```
   - パラメータ更新:

     ```bash
     aws cloudformation update-stack \
       --stack-name event-manager \
       --use-previous-template \
       --capabilities CAPABILITY_NAMED_IAM \
       --parameters ParameterKey=ECRImageExists,ParameterValue=yes \
                    ParameterKey=AppName,UsePreviousValue=true \
                    ParameterKey=RailsMasterKey,UsePreviousValue=true \
                    ParameterKey=DatabaseUsername,UsePreviousValue=true \
                    ParameterKey=DatabaseSnapshotIdentifier,UsePreviousValue=true \
                    ParameterKey=UseLatestDatabaseSnapshot,UsePreviousValue=true \
                    ParameterKey=CodePipelineArtifactsBucketName,UsePreviousValue=true \
                    ParameterKey=ECRRepositoryName,UsePreviousValue=true \
                    ParameterKey=AccessLogsBucketExists,UsePreviousValue=true \
                    ParameterKey=DomainName,UsePreviousValue=true \
                    ParameterKey=SubdomainName,UsePreviousValue=true \
                    ParameterKey=GitHubRepo,UsePreviousValue=true \
                    ParameterKey=GitHubBranch,UsePreviousValue=true \
                    ParameterKey=CodeStarConnectionArn,UsePreviousValue=true \
                    ParameterKey=EnableEcsExec,UsePreviousValue=true
     ```

   **注意**: スタックの更新完了まで通常5〜10分かかります。ECSサービスの更新やタスクの再デプロイに時間がかかります。

#### デプロイ後の確認（AWS コンソール）

- **アプリケーション URL**: CloudFormation > 対象スタック > Outputs
- **CodePipeline**: CodePipeline > 対象パイプラインの詳細
- **ECS サービス**: ECS > 対象クラスター > サービス詳細
- **ログ**: CloudWatch Logs > `/ecs/{AppName}` ロググループ
- **データベース監視**: CloudWatch > Performance Insights / Database Insights（Aurora MySQL）

#### スタック削除時の注意事項

CloudFormation スタックの削除は、以下の順番で実施してください。

1. **Route 53 の CNAME レコードを削除**

   スタック削除前に、Route 53 で作成された SSL 証明書の検証用 CNAME レコードを手動で削除する必要があります。ACM（AWS Certificate Manager）が DNS 検証のために自動的に作成した以下の2つの CNAME レコードを削除してください：

   - ルートドメイン用の検証 CNAME レコード: `_<random-string>.<DomainName>`
   - サブドメイン用の検証 CNAME レコード: `_<random-string>.<SubdomainName>`

   AWS コンソールの Route 53 から該当するホストゾーンを開き、CNAME レコードの一覧を確認して、ACM が作成した検証用の CNAME レコード（通常は `_` で始まる名前）を削除してください。

   **注意**: これらの CNAME レコードを削除しないと、スタック削除時にエラーが発生する可能性があります。

2. **CodePipeline Artifact 用 S3 バケットを空にする**

   スタック削除前に、必ず次のコマンドでバケットを空にします。

   ```bash
   # バケット名を確認（CloudFormation スタックの出力から取得）
   export BUCKET_NAME="<CodePipelineArtifactsBucketName>-<AccountId>-<Region>"

   # バケット内のオブジェクトを削除
   aws s3 rm s3://${BUCKET_NAME} --recursive

   # バージョニング付きオブジェクトをまとめて削除
   aws s3api list-object-versions \
     --bucket "${BUCKET_NAME}" \
     --output json \
   | jq -c '{Objects: [(.Versions[]? , .DeleteMarkers[]?) | {Key:.Key, VersionId:.VersionId}], Quiet: false}' \
   | aws s3api delete-objects \
       --bucket "${BUCKET_NAME}" \
       --delete file:///dev/stdin

   # 1000 件を超える場合は list-object-versions のレスポンスで IsTruncated が true かを確認し、
   # NextVersionIdMarker を指定して上記コマンドを繰り返してください。
   ```

3. **スタックを削除する**

   バケットを空にしたら、`aws cloudformation delete-stack --stack-name event-manager` を実行します。`aws cloudformation describe-stacks --stack-name event-manager --query "Stacks[0].StackStatus" --output text` で進捗を確認してください。

   **注意**: スタックの削除完了まで通常15〜20分かかります。Aurora、ECS、ALB、VPCエンドポイントなど多数のリソースを削除するため、時間がかかります。

## ECS Exec（オプション機能）

CloudFormation テンプレートでは `EnableEcsExec` パラメータを `yes` に設定すると、以下のリソースや設定が有効になります。

- ECS クラスターで `ExecuteCommandConfiguration` を有効化し、タスクコンテナへ SSM 経由で安全にシェル接続できる
- `SSMMessagesVPCEndpoint`（Interface VPC エンドポイント）を作成し、プライベートネットワークから ECS Exec が利用可能になる
- ECS サービスの `EnableExecuteCommand` を true に設定

`EnableEcsExec` を `no`（デフォルト）にすると上記の構成はスキップされ、ECS Exec/Sessions Manager 機能は利用できなくなりますが、Rails アプリケーションのデプロイ自体には影響しません。運用ポリシーに応じて選択してください。

**重要**: `EnableEcsExec` パラメータをスタック作成後に変更した場合、既存のタスクには自動的に反映されません。CloudFormation テンプレートでは、タスク定義に `ECS_EXEC_ENABLED` 環境変数を追加することで、パラメータ変更時にタスク定義が更新され、ECS サービスが新しいタスク定義を使用してタスクを自動的に再デプロイします。スタック更新後、新しいタスクが起動するまで数分かかる場合があります。
