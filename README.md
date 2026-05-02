# 🏛 Kazu AWS Enterprise Infrastructure

> エンタープライズ級AWSインフラをTerraformで完全構築したポートフォリオプロジェクト

## 📋 概要

本プロジェクトは、実際の本番環境で使用されるAWSベストプラクティスに基づいた  
フルスタック・エンタープライズ級インフラをTerraformでゼロから構築したものです。

- **期間**：10時間で全9フェーズ完成
- **リージョン**：ap-northeast-1（東京）
- **管理方法**：Terraform（モジュール構成）+ GitHub

---

## 🏗 アーキテクチャ

### 9レイヤー構成

| Layer | 名称 | 主要サービス |
|-------|------|-------------|
| 1 | ガバナンス層 | Organizations / SCP / CloudTrail |
| 2 | エッジ層 | CloudFront / WAF v2 |
| 3 | 認証・セキュリティ層 | Cognito / KMS / Secrets Manager / GuardDuty |
| 4 | Web・アプリ層 | ALB / EC2 ASG / ECS Fargate / API Gateway |
| 5 | 非同期・イベント駆動層 | S3 / EventBridge / SQS / DLQ / Lambda / SNS |
| 6 | データ層 | Aurora Serverless v2 / AWS Backup |
| 7 | 監視層 | CloudWatch / Alarms / GuardDuty |
| 8 | CI/CDインフラ層 | ECR / ECS |
| 9 | バックエンド管理 | S3 tfstate / DynamoDB Lock |

---

## 🛠 使用技術・サービス一覧

### AWS サービス（30+）
- **ネットワーク**：VPC / Subnet / IGW / Route Table / Security Group
- **コンピュート**：EC2 / Auto Scaling / ALB / ECS Fargate / ECR
- **データベース**：Aurora Serverless v2 / RDS Proxy
- **セキュリティ**：KMS / Secrets Manager / Cognito / GuardDuty / WAF v2
- **サーバーレス**：Lambda / API Gateway / S3 / SNS / SQS / EventBridge
- **監視**：CloudWatch / CloudTrail / Budgets
- **バックアップ**：AWS Backup
- **ガバナンス**：Organizations / SCP

### IaC・ツール
- **Terraform**：モジュール構成・S3リモートバックエンド・DynamoDB State Lock
- **GitHub**：ブランチ戦略（main / develop）
- **AWS CLI**：認証・運用

---

## 📁 Terraformディレクトリ構成

---

## 🚀 デプロイ手順

### 前提条件
- AWS CLI設定済み（AdministratorAccess）
- Terraform インストール済み

### 手順

```bash
# 1. リポジトリクローン
git clone https://github.com/o-kazuo/kazu-aws-full-project
cd kazu-aws-full-project

# 2. バックエンド作成（初回のみ）
cd terraform/backend
terraform init
terraform apply

# 3. 環境デプロイ
cd ../environments/dev
terraform init
terraform apply

# 4. 削除
terraform destroy
```

---

## 🔒 セキュリティ設計

- **全データ暗号化**：KMSによるS3・RDS・EBS暗号化
- **ゼロトラスト**：VPCエンドポイントで閉域通信
- **最小権限**：IAMロールによる最小権限設計
- **シークレット管理**：Secrets ManagerでDBパスワード管理
- **脅威検知**：GuardDutyによる機械学習ベースの異常検知
- **エッジ保護**：WAF v2でSQLi・XSS・DDoSをエッジで遮断
- **監査**：CloudTrailで全API操作を記録

---

## 💰 コスト設計

- **開発時**：作業後に`terraform destroy`でコスト最小化
- **Budgetsアラート**：月次予算超過時にメール通知
- **Serverless活用**：Aurora Serverless v2・Lambda・Fargateで使った分だけ課金

---

## 📊 Well-Architected Framework への対応

| 柱 | 実装内容 |
|----|---------|
| 運用上の優秀性 | IaC・CloudWatch・CloudTrail |
| セキュリティ | KMS・WAF・GuardDuty・Cognito |
| 信頼性 | マルチAZ・ASG・AWS Backup |
| パフォーマンス効率 | CloudFront・Aurora Serverless・Fargate |
| コスト最適化 | Serverless・Budgets・destroy運用 |

---

## 👤 Author

**K.Nishikawa**  
- GitHub：[@o-kazuo](https://github.com/o-kazuo)
- 構築期間：10時間（Terraform・AWS触り始めて2日目）
