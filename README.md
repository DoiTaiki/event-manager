# Event Manager

Rails アプリケーションを AWS 上で実行するためのイベント管理システムです。

## プロジェクトについて

本プロジェクトは、**CloudFormation による AWS インフラの実装に注力したプロジェクト**です。単一テンプレート内でのリソース定義整理や依存関係管理まで含めた、実践的な IaC（Infrastructure as Code）の実装となっています。

アプリケーション部分（Rails 8 + React 19）は、AWS インフラ上で動作するサンプルアプリケーションとして、学習目的で実装しています。アプリケーションの実装は、[TechRacho の「Rails 7とReactによるCRUDアプリ作成チュートリアル」](https://techracho.bpsinc.jp/hachi8833/2022_05_26/118202) を参考にしています。

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
- **データベース**: Aurora MySQL Serverless v2（マルチAZ構成）
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

詳細は [デプロイ手順](./docs/DEPLOYMENT.md#アーキテクチャ) を参照してください。

## クイックスタート

### Dev Container を使用（推奨）

1. リポジトリをクローン
2. VS Code で開く
3. コマンドパレット（`Cmd+Shift+P` / `Ctrl+Shift+P`）から「Dev Containers: Reopen in Container」を選択
4. Dev Container 起動後、自動的にセットアップが実行されます
5. ターミナルで `bin/dev` を実行

アプリケーションは `http://localhost:3000` でアクセスできます。

詳細なセットアップ手順は [開発ガイド](./docs/DEVELOPMENT.md) を参照してください。

## ドキュメント

- **[開発ガイド](./docs/DEVELOPMENT.md)**: 開発環境のセットアップ、構成、テスト実行方法
- **[デプロイ手順](./docs/DEPLOYMENT.md)**: AWS アーキテクチャ、デプロイ手順、オプション機能
