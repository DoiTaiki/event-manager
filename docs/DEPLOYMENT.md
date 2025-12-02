# デプロイ手順

## アーキテクチャ

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
- **データベース**: Aurora MySQL Serverless v2（マルチAZ構成）
- **データベース監視**: CloudWatch Database Insights(Standard) によるパフォーマンス監視
- **CI/CD**: CodePipeline + CodeBuild による自動デプロイ
- **ストレージ**: ECR（Docker イメージ）、S3（ログ・アーティファクト）
- **セキュリティ**: Secrets Manager、VPC エンドポイント、セキュリティグループ
- **運用**: ECS Exec（任意）でタスク内コンテナへ SSM セッション接続可能

### アーキテクチャ図

AWS アーキテクチャの詳細な図を以下の形式で提供しています：

![AWSアーキテクチャ図](../aws-architecture-diagram.svg)

**図の内容**: VPC、サブネット、ECS、Aurora、CI/CD パイプライン、Route 53、ALB などの詳細な構成

**ファイル形式**:
- **SVG形式（画像表示用）**: [`aws-architecture-diagram.svg`](../aws-architecture-diagram.svg) - GitHub上で画像として表示されます
- **Draw.io形式（編集用）**: [`aws-architecture-diagram.drawio`](../aws-architecture-diagram.drawio) - 図の編集に使用します
- **Markdown形式（詳細説明）**: [`aws-architecture-diagram.md`](../aws-architecture-diagram.md) - 各コンポーネントの詳細な説明

**図の閲覧・編集方法**:
- **GitHub**: リポジトリにプッシュすると、GitHub上で直接図を表示・編集できます
- **Draw.io オンラインエディタ**: [app.diagrams.net](https://app.diagrams.net/) でファイルを開いて編集可能
- **VS Code**: [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) 拡張機能をインストールすると、VS Code内で直接編集できます

## AWS へのデプロイ

**重要**: AWS にデプロイする際には、予めドメインを登録しておく必要があります。Route 53 でホストゾーンを作成するか、既存のドメインを Route 53 に移管してください。

### 1. CloudFormation テンプレートの準備

[`rails-ecs-codepipeline-cf.yaml`](../rails-ecs-codepipeline-cf.yaml) で使用するパラメータの確認(スタックの作成・更新時に指定)。パラメータ毎の詳細はテンプレートのParametersセクションを確認してください。

#### 必須パラメータ

- `RailsMasterKey`: `config/master.key` の値
- `CodeStarConnectionArn`: CodeStar Connections の ARN
- `GitHubRepo`: GitHub リポジトリ（例: owner/repo）
- `DomainName`: ドメイン名（例: example.com）
- `SubdomainName`: サブドメイン名（例: www.example.com）

#### 更新が必要なパラメータ

スタック作成時は `no`、後で `yes` に更新：

- `ECRImageExists`: デフォルト値 `no` のままスタックを作成し、CodePipeline が Docker イメージをビルド・プッシュした後に `yes` に更新して ECS サービスを有効化（デフォルト: no）

#### 再デプロイ時に使用するパラメータ

既存リソースを再利用する場合：

- `DatabaseSnapshotIdentifier`: 復元したいスナップショット ARN（デフォルト: 空文字）。既存のデータベーススナップショットから復元する場合に使用。`UseLatestDatabaseSnapshot`が`yes` の場合、無視されます。
- `UseLatestDatabaseSnapshot`: 最新の手動スナップショットを自動的に使用するか（yes/no、デフォルト: no）。既存のデータベースクラスターの最新手動スナップショットから自動復元する場合に `yes` を設定。
- `AccessLogsBucketExists`: ALB アクセスログ用の既存バケットが存在する場合は `yes`（デフォルト: no）。再デプロイ時に既存バケットを再利用する場合に使用。**注意**: このバケットは `DeletionPolicy: Retain` により、スタック削除時に削除されません。

#### 任意パラメータ

デフォルト値あり：

- `AppName`: アプリケーション名（デフォルト: EventManager）
- `DatabaseUsername`: データベースユーザー名（デフォルト: root）
- `EnableDBAutoPause`: Aurora Serverless v2 の自動ポーズ機能を有効にするか（yes/no、デフォルト: yes）。`yes` は最小容量 0 ACU で自動ポーズを有効化（非アクティブ後約 12〜13 分でポーズ、復帰は約 15 秒）。`no` は最小容量 0.5 ACU で常時起動状態を維持（本番環境向け）。（詳細は「[オプション機能](#オプション機能)」の「[Aurora 自動ポーズ機能](#aurora-自動ポーズ機能)」を参照）。
- `CodePipelineArtifactsBucketName`: CodePipeline アーティファクト用 S3 バケットのベース名（デフォルト: codepipeline-artifacts）
- `ECRRepositoryName`: Docker イメージを push する ECR リポジトリ名（デフォルト: event-manager-repo）
- `GitHubBranch`: 監視するブランチ（デフォルト: main）
- `EnableEcsExec`: ECS Exec（SSM Session Manager）を有効にするか（yes/no、デフォルト: no）。（詳細は「[オプション機能](#オプション機能)」の「[ECS Exec](#ecs-exec)」を参照）。

### 2. CodeStar Connection の作成

AWS コンソールで CodeStar Connections を作成し、GitHub アカウントと接続します。

- AWS コンソールで「CodePipeline」→「Settings」→「Connections」に移動
- 「Create connection」をクリック
- 「GitHub」を選択して「Next」をクリック
- 接続名を入力し、「Connect to GitHub」をクリック
- GitHub の認証画面で認証を完了
- 接続が「Available」状態になるまで待機（数分かかる場合があります）
- 接続の ARN をコピーして、`CodeStarConnectionArn` パラメータに使用

### 3. CloudFormation スタックの作成

テンプレートは 51,200 バイトのサイズ制限を超えるため、`--template-body` ではなく S3 へアップロードして `--template-url` で参照する必要があります。

#### S3バケットの準備

テンプレートをアップロードするための S3 バケットが必要です。既存のバケットがない場合は作成してください。

```bash
# 既存のS3バケットを確認
aws s3 ls --region ap-northeast-1

# 新規バケットを作成する場合
aws s3 mb s3://your-template-bucket --region ap-northeast-1

# バケット名を環境変数に渡す
export TEMPLATE_BUCKET_NAME="your-template-bucket"
```

#### テンプレートをS3にアップロード

```bash
aws s3 cp rails-ecs-codepipeline-cf.yaml s3://${TEMPLATE_BUCKET_NAME}/cf/rails-ecs-codepipeline-cf.yaml
```

#### スタック作成コマンド

必須パラメータを含む最小構成：

```bash
aws cloudformation create-stack \
--stack-name event-manager \
--template-url https://${TEMPLATE_BUCKET_NAME}.s3.amazonaws.com/cf/rails-ecs-codepipeline-cf.yaml \
--parameters ParameterKey=RailsMasterKey,ParameterValue=your-master-key \
               ParameterKey=CodeStarConnectionArn,ParameterValue=arn:aws:codestar-connections:region:account-id:connection/connection-id \
               ParameterKey=GitHubRepo,ParameterValue=owner/repo \
               ParameterKey=DomainName,ParameterValue=example.com \
               ParameterKey=SubdomainName,ParameterValue=www.example.com \
--capabilities CAPABILITY_NAMED_IAM \
--region ap-northeast-1
```

**注意**:
- 上記コマンドは必須パラメータのみの例です。任意パラメータのデフォルト値を変更したい場合は、`--parameters` に追加してください。
- **`ECRImageExists`パラメータはデフォルト値`no`のままにしてください**。CodePipeline が Docker イメージをビルド・プッシュした後に `yes` に更新します（詳細は「5. ECS サービスの有効化」を参照）。
- スタックの作成完了まで通常20〜30分かかります。VPC、サブネット、Aurora、ECS、ALB、Route 53、ACM証明書など多数のリソースを作成するため、時間がかかります。

#### デプロイの進捗確認

```bash
aws cloudformation describe-stacks \
  --stack-name event-manager \
  --query "Stacks[0].StackStatus" \
  --output text
```

### 4. Route 53 ネームサーバーの設定

ドメインの登録場所がRoute 53 Domains（同一アカウント）ではない場合、手動設定が必要です。

- **Route 53 Domains（同一アカウント）**: 自動設定されます。手動設定は不要です。
- **外部レジストラ（お名前.com、ムームードメイン、GoDaddy など）または Route 53 Domains（別アカウント）**: 下記コマンドで取得したネームサーバーを手動設定してください。

#### ネームサーバーの取得

```bash
aws cloudformation describe-stacks \
  --stack-name event-manager \
  --query "Stacks[0].Outputs[?OutputKey=='Route53NameServers'].OutputValue" \
  --output text
```

#### 手動設定方法

- **外部レジストラの場合**: 取得したネームサーバーを各レジストラの管理画面で設定してください。
- **Route 53 Domains（別アカウント）の場合**: AWSコンソールで「Route 53」→「Registered domains」→対象ドメインを選択→「Actions」→「Edit name servers」で取得したネームサーバーを設定してください。

### 5. ECS サービスの有効化

スタックを作成するとCodePipeline が自動的にトリガーされ、Docker イメージがビルド・プッシュされます。イメージが ECR にプッシュされたら、`ECRImageExists` をデフォルト値 `no` → `yes` に更新して ECS サービスを有効化させます。

#### イメージ push の確認

```bash
aws ecr describe-images \
   --repository-name event-manager-repo \
   --query "imageDetails[].imageTags" \
   --output table
```

#### パラメータ更新

```bash
aws cloudformation update-stack \
   --stack-name event-manager \
   --use-previous-template \
   --capabilities CAPABILITY_NAMED_IAM \
   --parameters ParameterKey=ECRImageExists,ParameterValue=yes \
               ParameterKey=RailsMasterKey,UsePreviousValue=true \
               ParameterKey=CodeStarConnectionArn,UsePreviousValue=true \
               ParameterKey=GitHubRepo,UsePreviousValue=true \
               ParameterKey=DomainName,UsePreviousValue=true \
               ParameterKey=SubdomainName,UsePreviousValue=true \
   --region ap-northeast-1
```

**注意**:
- `update-stack` で `--parameters` を指定した場合、**指定されていないパラメータはデフォルト値に戻ります**（前回の値は保持されません）。上記のコマンドでは、必須パラメータと更新対象パラメータのみを指定しています。もし `create-stack` でデフォルト値以外を指定した任意パラメータ（例: `UseLatestDatabaseSnapshot=yes`、`AccessLogsBucketExists=yes` など）がある場合は、`ParameterKey=<パラメータ名>,UsePreviousValue=true` を追加してください。
- スタックの更新完了まで通常5〜10分かかります。ECSサービスの更新やタスクの再デプロイに時間がかかります。

## デプロイ後の確認（AWS コンソール）

- **アプリケーション URL**: CloudFormation > 対象スタック > Outputs
- **CodePipeline**: CodePipeline > 対象パイプラインの詳細
- **ECS サービス**: ECS > 対象クラスター > サービス詳細
- **ログ**: CloudWatch > Log groups > `/ecs/{AppName}` ロググループ
- **データベース監視**: CloudWatch > Database Insights > 対象DBインスタンス

## スタック削除時の注意事項

CloudFormation スタックの削除は、以下の順番で実施してください。

### 1. Route 53 の CNAME レコードを削除

スタック削除前に、Route 53 で作成された SSL 証明書の検証用 CNAME レコードを手動で削除する必要があります。ACM（AWS Certificate Manager）が DNS 検証のために自動的に作成した以下の2つの CNAME レコードを削除してください：

- ルートドメイン用の検証 CNAME レコード: `_<random-string>.<DomainName>`
- サブドメイン用の検証 CNAME レコード: `_<random-string>.<SubdomainName>`

AWS コンソールの Route 53 から該当するホストゾーンを開き、CNAME レコードの一覧を確認して、ACM が作成した検証用の CNAME レコード（通常は `_` で始まる名前）を削除してください。

**注意**: これらの CNAME レコードを削除しないと、スタック削除時にエラーが発生する可能性があります。

### 2. CodePipeline Artifact 用 S3 バケットを空にする

スタック削除前に、必ず次のコマンドでバケットを空にします。

```bash
# バケット名を確認（CloudFormation スタックの出力から取得）
export CP_ARTIFACT_BUCKET_NAME="<CodePipelineArtifactsBucketName>-<AccountId>-<Region>"

# バケット内のオブジェクトを削除
aws s3 rm s3://${CP_ARTIFACT_BUCKET_NAME} --recursive

# バージョニング付きオブジェクトをまとめて削除
aws s3api list-object-versions \
  --bucket "${CP_ARTIFACT_BUCKET_NAME}" \
  --output json \
| jq -c '{Objects: [(.Versions[]? , .DeleteMarkers[]?) | {Key:.Key, VersionId:.VersionId}], Quiet: false}' \
| aws s3api delete-objects \
    --bucket "${CP_ARTIFACT_BUCKET_NAME}" \
    --delete file:///dev/stdin
```

**1000 件を超える場合**: 上記のコマンドでは削除しきれない場合があります。その場合は、AWS コンソールから S3 バケットを開き、「空にする」機能を使用してバケットを空にしてください。AWS コンソールでは、バージョニング付きオブジェクトも含めてすべてのオブジェクトを削除できます。

### 3. スタックを削除する

バケットを空にしたら、`aws cloudformation delete-stack --stack-name event-manager` を実行します。`aws cloudformation describe-stacks --stack-name event-manager --query "Stacks[0].StackStatus" --output text` で進捗を確認してください。

**注意**: スタックの削除完了まで通常15〜20分かかります。Aurora、ECS、ALB、VPCエンドポイントなど多数のリソースを削除するため、時間がかかります。

### 削除後に残るリソース

- **ALB アクセスログ用 S3 バケット**: `DeletionPolicy: Retain` により、スタック削除後も残ります。不要な場合は手動で削除してください。
- **データベーススナップショット**: Aurora の自動バックアップにより作成されたスナップショットは残ります。不要な場合は手動で削除してください。
- **ECS タスク定義**: `DeletionPolicy: Retain` により残ります。通常は問題ありませんが、不要な場合は手動で削除できます。
- **CloudWatch Logs ロググループ**: `/ecs/${AppName}` ロググループは自動削除されません。不要な場合は手動で削除してください。
- **ECR イメージ**: 通常は ECR リポジトリと共に削除されますが、リポジトリの削除が失敗した場合などに残る可能性があります。不要な場合は手動で削除してください。

## オプション機能

### Aurora 自動ポーズ機能

`EnableDBAutoPause` パラメータにより、Aurora Serverless v2 の自動ポーズ機能を制御できます。

#### 自動ポーズ機能有効（`EnableDBAutoPause: yes`、デフォルト）

- 最小容量 0 ACU で自動ポーズ機能が有効になります
- 設定上は 300 秒（5 分）間リクエストが無い場合に自動ポーズします。ただし、実際には内部処理の完了を待つため、約 12〜13 分でポーズされます
- アクセスが再開されると、通常は 15 秒程度で自動復帰します（24 時間以上ポーズされた場合は 30 秒以上かかることがあります）
- この挙動により、検証環境やトラフィックの少ない時間帯のコスト最適化に役立ちます

#### 常時起動モード（`EnableDBAutoPause: no`）

- 最小容量 0.5 ACU でデータベースは常時起動状態を維持します
- 自動ポーズは無効になります
- 本番環境や常時アクセスが必要な環境に適しています

#### 実際のポーズ待機が長めになる主な要因

- Aurora 内部プロセス（ストレージ同期、バックグラウンドタスク、トランザクションログ書き込み、ヘルスチェック）の完了待機
- マルチ AZ（Writer/Reader）間でのポーズ順序と状態同期（Reader → Writer の順にポーズ）
- データ整合性や自動バックアップとの競合回避を目的とした安全マージン

#### 推奨される運用

自動ポーズ機能は検証環境やトラフィックの少ない時間帯のコスト最適化に有効です。本番環境や常時アクセスが必要な環境では、`EnableDBAutoPause` を `no` に設定して常時起動モードを使用することを推奨します。

### ECS Exec

`EnableEcsExec` パラメータを `yes` に設定してスタックを作成・更新すると、以下のリソースや設定が有効になります。

- ECS クラスターで `ExecuteCommandConfiguration` を有効化し、タスクコンテナへ SSM 経由で安全にシェル接続できる
- `SSMMessagesVPCEndpoint`（Interface VPC エンドポイント）を作成し、プライベートネットワークから ECS Exec が利用可能になる
- ECS サービスの `EnableExecuteCommand` を true に設定

`EnableEcsExec` を `no`（デフォルト）にすると上記の構成はスキップされ、ECS Exec/Sessions Manager 機能は利用できなくなりますが、Rails アプリケーションのデプロイ自体には影響しません。

#### 推奨される運用

Interface VPC エンドポイント（`SSMMessagesVPCEndpoint`）は時間単位の料金が発生し、一般的に割高です。そのため、**常時有効にするのではなく、必要な時のみ一時的に `EnableEcsExec` を `yes` に更新して使用し、作業完了後は `no` に戻す運用を推奨します**。

#### 使用例

ECS Exec を使用してコンテナに接続する場合、以下のコマンドを実行します。クラスター名、タスクID、コンテナ名は実際の値に置き換えてください。

```bash
aws ecs execute-command \
   --region ap-northeast-1 \
   --cluster <クラスター名> \
   --task <タスクID> \
   --container <コンテナ名> \
   --command "/bin/bash" \
   --interactive
```

#### 注意

`EnableEcsExec` パラメータをスタック作成後に更新した場合、ECS サービスが新しいタスク定義を使用してタスクを自動的に再デプロイします。スタックの更新完了まで通常5〜10分かかります。
