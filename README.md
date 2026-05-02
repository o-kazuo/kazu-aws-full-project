# 🏆 Kazu AWS Full Infrastructure Project

## 概要
「鉄壁・不沈・自動化」をコンセプトに、エンタープライズ級AWSインフラをTerraformで完全コード化したポートフォリオプロジェクト。

## アーキテクチャ

## 使用技術・AWSサービス

| カテゴリ | サービス | 用途 |
|---|---|---|
| ネットワーク | VPC / Subnet / IGW | 6サブネット構成（Public/App/DB × 2AZ） |
| 負荷分散 | ALB | ユーザーリクエストの振り分け |
| コンピュート | EC2 / Auto Scaling | 負荷に応じた自動スケーリング |
| データベース | RDS MySQL 8.0 | マルチAZ・KMS暗号化 |
| セキュリティ | KMS / Secrets Manager | 暗号化・パスワード管理 |
| 運用 | SSM Session Manager | キーレスEC2接続 |
| ストレージ | S3 | KMS暗号化・イベントトリガー |
| サーバーレス | Lambda (Python) | 画像リサイズ自動処理 |
| 通知 | SNS | 処理完了メール通知 |
| IaC | Terraform | 全リソースのコード管理 |
| バージョン管理 | GitHub | 構築履歴・ポートフォリオ |

## 実装した機能

### インフラ
- VPC設計（10.0.0.0/16 / 6サブネット / マルチAZ）
- ALB + Auto Scaling Group（min:1 max:3）
- RDS MySQL 8.0（マルチAZ・KMS暗号化）
- Secrets Managerによるパスワード管理
- SSMセッションマネージャーによるキーレス接続
- KMSによるS3・RDS暗号化

### アプリケーション
- PHPメモアプリ（EC2 + RDS連携）
- 画像リサイズパイプライン（S3 → Lambda → S3 → SNS）

### セキュリティ
- IAMロールによる最小権限設計
- セキュリティグループによる多段防御
- KMS暗号化（S3・RDS）
- Secrets Managerによる機密管理

## Terraformファイル構成

| ファイル | 内容 |
|---|---|
| vpc.tf | VPC・サブネット・ルートテーブル |
| EC2_Instance.tf | 起動テンプレート・ASG・ALB |
| RDS.tf | RDS・マルチAZ・KMS暗号化 |
| iam.tf | IAMロール・ポリシー |
| s3_lambda_sns.tf | S3・Lambda・SNS・KMS暗号化 |
| kms.tf | KMSキー |
| budgets.tf | 予算アラート |

## デプロイ方法

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 削除方法

```bash
terraform destroy
```

## 今後の予定
- Route 53 + CloudFront（CDN・独自ドメイン）
- WAF（セキュリティ強化）
- Cognito（ユーザー認証）
- ECS on Fargate（コンテナ化）
- EventBridge（イベント駆動）
- Aurora + ElastiCache + DynamoDB
- CloudWatch（監視・アラート）
- Slack通知

