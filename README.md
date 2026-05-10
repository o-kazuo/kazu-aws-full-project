---

## 🚀 デプロイ手順

### 前提条件

- AWS CLI設定済み（AdministratorAccess）
- Terraform インストール済み
- WSL（Ubuntu）環境

### 手順

```bash
# 1. リポジトリクローン
git clone https://github.com/o-kazuo/kazu-aws-full-project
cd kazu-aws-full-project

# 2. 時刻同期（WSL必須）
sudo ntpdate pool.ntp.org

# 3. バックエンド作成（初回のみ）
cd terraform/backend
terraform init
terraform apply

# 4. 環境デプロイ
cd ../environments/dev
terraform init
terraform apply

# 5. アプリデプロイ（GitHub Actionsが自動実行）
git push origin main

# 6. 削除前の準備
# ECR・S3・BackupVaultを先に空にしてから
terraform destroy
```

---

## 🔒 セキュリティ設計

- **全データ暗号化**：KMS（ケーエムエス）によるS3・RDS・DynamoDB暗号化
- **閉域通信**：S3・DynamoDB VPCゲートウェイエンドポイントでインターネット経由なし
- **最小権限**：IAMロールによる最小権限設計・OIDC認証でアクセスキー不要
- **シークレット管理**：Secrets Manager（シークレッツ マネージャー）でDB接続情報を管理・Terraform完全自動化
- **脅威検知**：GuardDuty（ガードデューティ）による機械学習ベースの異常検知
- **エッジ保護**：WAF v2（ワフ）でSQLi・XSS・DDoSをエッジで遮断
- **監査**：CloudTrail（クラウドトレイル）で全API操作を記録・専用S3バケットに保存

---

## 📈 主要な実装ポイント

### ECS AutoScaling（オートスケーリング）
CPU使用率70%超えで自動スケールアウト（最小1・最大5タスク）、30%以下でスケールイン。CloudWatchアラームと連携。

### DB読み書き分離
RDS Proxy（アールディーエス プロキシ）のWriter・Readerエンドポイントを分離。FastAPIの書き込み処理はWriter、読み込み処理はReaderに振り分け。
> ※現在は開発環境のためAurora Serverless v2を単一インスタンスで運用。本番環境ではReaderインスタンスを追加して完全な読み書き分離を実現。

### CI/CD完全自動化
git pushのみでECRイメージビルド・DBマイグレーション・ECSデプロイ・フロントエンドビルド・S3デプロイ・CloudFrontキャッシュクリアまで自動実行。

### IaC完全管理
手動CLIでのインフラ変更は一切なし。Secrets Managerの値もTerraformで管理。destroy→applyで完全復元可能。

---

## 💰 コスト設計

- **開発時**：作業後に`terraform destroy`でコスト最小化
- **Budgetsアラート**：月次予算超過時にメール通知
- **Serverless活用**：Aurora Serverless v2・Lambda・Fargateで使った分だけ課金

---

## 📊 Well-Architected Framework への対応

| 柱 | 実装内容 |
|----|---------|
| 運用上の優秀性 | IaC完全管理・CI/CD自動化・CloudWatch監視 |
| セキュリティ | KMS・WAF・GuardDuty・Cognito・OIDC・最小権限IAM |
| 信頼性 | マルチAZ・ECS AutoScaling・AWS Backup |
| パフォーマンス効率 | CloudFront・Aurora Serverless v2・Fargate・DB読み書き分離 |
| コスト最適化 | Serverless・Budgets・destroy運用・VPCエンドポイント |

---

## 🔮 今後の予定

- [ ] ALBのHTTPS化（ACM証明書・独自ドメイン取得後）
- [ ] Aurora Readerインスタンス追加による完全な読み書き分離
- [ ] Amazon Athena（アテナ）によるログ分析基盤
- [ ] RDSパスワード強化
- [ ] KMSポリシーの特定ARNへの絞り込み

---

## 👤 Author

**K.Nishikawa**
- GitHub：[@o-kazuo](https://github.com/o-kazuo)
- 学習期間：約5ヶ月（AWS資格取得→コンソール構築→IaC・CI/CD実装）
- 取得資格：AWS Cloud Practitioner（クラウドプラクティショナー）/ AWS Solutions Architect Associate（ソリューションアーキテクト アソシエイト）