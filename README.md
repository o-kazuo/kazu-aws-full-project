# kazu-aws-full-project

## 概要
エンタープライズ級AWSインフラを「鉄壁・不沈・自動化」をコンセプトにTerraformで完全コード化したプロジェクト。

## 使用技術
- **IaC**: Terraform
- **クラウド**: AWS (ap-northeast-1)
- **言語**: PHP 8.2
- **DB**: MySQL 8.0 (RDS)

## アーキテクチャ
- VPC (10.0.0.0/16) / 6サブネット構成
- EC2 (Amazon Linux 2023 / PHP 8.2)
- RDS (MySQL 8.0 / db.t3.micro)
- Secrets Manager (DBパスワード管理)
- IAMロール (EC2 ⇔ Secrets Manager連携)
- SSMセッションマネージャー (キーレス接続)

## 構成ファイル
| ファイル | 内容 |
|---|---|
| vpc.tf | VPC・サブネット・ルートテーブル |
| ec2_instance.tf | EC2・セキュリティグループ |
| RDS.tf | RDS・DBサブネットグループ |
| iam.tf | IAMロール・ポリシー |
| secrets.tf | Secrets Manager |
| budgets.tf | 予算アラート |

## デプロイ方法
```bash
cd terraform
terraform init
terraform apply
```

## 削除方法
```bash
terraform destroy
```

## 今後の予定
- ALB + Auto Scaling Group
- Lambda + S3トリガー
- KMS暗号化
- VPCエンドポイント全実装