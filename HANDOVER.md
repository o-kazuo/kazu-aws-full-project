# KazuAI Platform 引き継ぎ書
## Phase N+2 更新版（2026年5月10日更新）

⚠️ 絶対ルール

- AWSリソースの変更は全部Terraformから！手動CLIでの変更は絶対NG
- 機密情報はSecretsManagerで管理！GitHubへの露出は絶対NG
- 全作業はWSLで統一！PowerShellとの混在はNG
- 場当たり的な修正は絶対にしない！根本原因を特定してから修正する！
- terraform planで確認 → terraform applyで実行の順番を守る
- 確認系コマンド（describe・logs・curl）はCLI直接でOK
- インフラ変更 → terraform apply → git push
- アプリコード変更 → git pushのみ

## 1. 現在の状態

| コンポーネント | 状態 | 備考 |
|---|---|---|
| インフラ（Terraform） | ✅ 完了 | 全手動作業を自動化済み |
| バックエンド（FastAPI） | ✅ 動作確認済み | ECS Fargate・/api/healthで確認済み |
| CI/CD（GitHub Actions） | ✅ 完了 | OIDC認証・アクセスキー不要 |
| SecretsManager連携 | ✅ 完了 | Terraform完全管理・手動CLI変更なし |
| フロントエンド（React/Vite） | ✅ 完了 | CloudFront経由でHTTPS配信 |
| CloudFront | ✅ 完了 | SPA対応・カスタムエラーレスポンス・キャッシュ最適化 |
| RDS Proxy | ✅ 完了 | Writer/Reader分離設計済み |
| WAF | ✅ 完了 | SQLi・一般攻撃対策済み |
| IAM最小権限 | ✅ 完了 | OIDC認証・ECR/ECS特定ARNに絞り込み済み |
| Lambda（画像処理） | ✅ 完了 | boto3除外・__pycache__除外・ZIPサイズ削減済み |
| CloudTrail専用バケット | ✅ 完了 | inputバケットから分離済み |
| SGルール管理 | ✅ 完了 | egress競合修正済み |
| DynamoDB APIエンドポイント | ✅ 完了 | GET /api/ai/image-analysis追加済み |
| ECSタスクロール権限 | ✅ 完了 | S3・Rekognition・Cognito・DynamoDB・KMS権限追加済み |
| Cognito認証 | ✅ 動作確認済み | terraform output・SecretsManagerで自動化済み |
| Alembicマイグレーション | ✅ 完了 | 専用ECSタスク・GitHub Actions自動化済み |
| /api/ai/upload | ✅ 動作確認済み | CloudFront経由でファイルアップロード確認済み |
| /api/ai/results | ✅ 動作確認済み | CloudFront経由でDB結果取得確認済み |
| フロントエンドUI | ✅ 完了 | 日本語化・モバイル対応・自動翻訳無効化済み |
| ECS AutoScaling | ✅ 完了 | CPU70%スケールアウト・最小1・最大5タスク |
| CloudWatch監視ダッシュボード | ✅ 完了 | ECS・RDS・Lambda・CloudFront・WAF・DynamoDB |
| DB読み書き分離 | ✅ 完了 | Writer/Reader設計済み（現在は単一インスタンスのためWriter共用） |
| S3・DynamoDB VPCエンドポイント | ✅ 完了 | ゲートウェイエンドポイント追加済み |
| uvicornログレベル | ✅ 完了 | debugからinfoに変更済み |
| Node.js | ✅ 完了 | 20から24にアップグレード済み |
| KMSポリシー | ✅ 完了 | ECR・ECS特定ARNに絞り込み済み |
| SecretsManager自動化 | ✅ 完了 | DATABASE_URL_WRITER/READERをTerraformで管理 |
| CloudFrontキャッシュ自動クリア | ✅ 完了 | GitHub Actionsデプロイ後に自動実行 |
| ECS AutoScaling | ⏳ 未着手 | 次のタスク |
| ALBのHTTPS化 | ⏳ 未着手 | ドメイン取得後 |

## 2. 重要な値

### 固定値（destroyしても変わらない）

| 項目 | 値 |
|---|---|
| Lex Bot Alias ID | TSTALIASID |
| ECR URI | 227811178732.dkr.ecr.ap-northeast-1.amazonaws.com/dev-web-app |
| ECS Cluster | dev-ecs-cluster |
| ECS Service | dev-web-service |
| S3 Bucket（フロント） | dev-frontend-227811178732 |
| S3 Bucket（input） | dev-input-bucket-227811178732 |
| S3 Bucket（output） | dev-output-bucket-227811178732 |
| S3 Bucket（CloudTrail） | dev-cloudtrail-227811178732 |
| RDS Endpoint | dev-aurora-cluster.cluster-cr40amieu2yc.ap-northeast-1.rds.amazonaws.com |
| SecretsManager（RDS Proxy用） | dev-db-secret-proxy |
| SecretsManager（アプリ用） | dev-app-secret |
| SecretsManager（テストユーザー） | dev-test-user-secret |
| AWS Account ID | 227811178732 |
| AWS Region | ap-northeast-1 |
| DynamoDB（画像分析） | dev-image-analysis |
| テストユーザー | SecretsManagerから取得（dev-test-user-secret） |

### applyのたびに変わる値（terraform outputで取得）

| 項目 | 確認コマンド |
|---|---|
| ALB DNS | aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text |
| Lex Bot ID | terraform output lex_bot_id |
| CloudFront URL | terraform output cloudfront_domain_name |
| GitHub Actions Role ARN | terraform output github_actions_role_arn |
| Cognito User Pool ID | terraform output cognito_user_pool_id |
| Cognito Client ID | terraform output cognito_client_id |

## 3. アーキテクチャ
ユーザー → HTTPS → CloudFront（WAF付き）
├── /api/* → ALB → ECS Fargate（FastAPI）→ RDS Proxy → Aurora MySQL 8.0
└── /*    → S3（React/Vite）OAC保護
画像処理：S3(input/images/) → Lambda → リサイズ・Rekognition・DynamoDB・SNS
監査ログ：CloudTrail → S3(dev-cloudtrail-227811178732)

## 4. インフラ再構築手順（destroy後の復元）

### Step 1: 時刻同期
```bash
sudo ntpdate pool.ntp.org
```

### Step 2: Terraform apply
```bash
cd ~/kazu-aws-full-project/terraform/environments/dev
terraform init -reconfigure
terraform plan
terraform apply
```

### Step 3: デプロイ
```bash
cd ~/kazu-aws-full-project
git commit --allow-empty -m "ci: trigger deploy"
git push origin main
```

### Step 4: 動作確認
```bash
curl -s https://$(terraform output -raw cloudfront_domain_name)/api/health
```

⚠️ dev-test-user-secretがエラーになる場合：
```bash
aws secretsmanager delete-secret \
  --secret-id dev-test-user-secret \
  --force-delete-without-recovery
terraform apply
```

## 5. 次にやること

| # | タスク | 内容 |
|---|---|---|
| 1 | README編集 | 自分の言葉で内容を書き直す・面接準備 |
| 2 | 履歴書作成 | READMEをベースに最強の履歴書を作成 |
| 3 | ALBのHTTPS化 | ACM証明書・ドメイン取得後 |
| 4 | DBクエリ確認 | RDS・DynamoDBのデータをクエリして中身を確認 |
| 5 | Athena実装 | ログ分析基盤（任意） |

## 6. やることリスト（技術的負債）

| # | タスク | 内容 |
|---|---|---|
| 1 | RDSパスワード強化 | 強いパスワードに変更してSecretsManagerで管理 |
| 2 | ALBのHTTPS化 | ACM証明書を設定してHTTPSに対応（ドメイン取得後） |
| 3 | Aurora Readerインスタンス追加 | 完全な読み書き分離を実現（本番環境向け） |

## 7. Terraformモジュール構成
terraform/modules/
networking/  database/  security/  compute/  serverless/
monitoring/  backup/    cdn/       lex/      container/
auth/        messaging/ governance/ cache/   batch/

### モジュール依存関係
networking → database → security → compute → container

## 8. SGルール管理

⚠️ egressブロックとaws_security_group_ruleを混在させない！

| ルール | 管理場所 |
|---|---|
| ECS → RDS Proxy（3306） | container/main.tf |
| RDS Proxy → Aurora（3306） | database/main.tf |
| ECS → Aurora直接（3306）※マイグレーション用 | database/main.tf |

## 9. SecretsManager構成

| Secret名 | 用途 | KMS暗号化 |
|---|---|---|
| dev-db-secret-proxy | RDS ProxyがAuroraに接続 | なし |
| dev-app-secret | DATABASE_URL_WRITER/READER | あり |
| dev-test-user-secret | テストユーザー情報 | あり |

## 10. DB読み書き分離

- **Writer**: dev-rds-proxy.proxy-xxx.ap-northeast-1.rds.amazonaws.com
- **Reader**: dev-rds-proxy-reader.endpoint.proxy-xxx.ap-northeast-1.rds.amazonaws.com
- 現在は単一インスタンスのためWriterで両方処理
- 本番環境ではReaderインスタンスを追加して完全分離

## 11. Lambda（画像処理）構成

| 項目 | 値 |
|---|---|
| 関数名 | dev-image-resize |
| ランタイム | Python 3.11 |
| メモリ | 512MB |
| タイムアウト | 60秒 |
| トリガー | S3（images/プレフィックスのみ） |

### ZIPの再作成方法（boto3除外・__pycache__除外）
```bash
mkdir -p ~/lambda_build/package && cd ~/lambda_build
pip install pillow \
  --target ./package \
  --platform manylinux2014_x86_64 \
  --python-version 3.11 \
  --only-binary=:all: \
  --break-system-packages
find ./package -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null
cp ~/kazu-aws-full-project/package/lambda_function.py ~/lambda_build/package/
cd ~/lambda_build/package
zip -r ~/kazu-aws-full-project/package/lambda_function.zip .
```

## 12. GitHub Actions（deploy.yml）フロー
git push
→ ECRにイメージビルド・プッシュ
→ マイグレーション専用ECSタスク起動（Aurora直接接続）
→ タスク完了待機・成功確認
→ ECSサービスデプロイ（RDS Proxy経由）
→ フロントエンドビルド・S3デプロイ（キャッシュ制御付き）
→ CloudFrontキャッシュ自動クリア

## 13. destroy前の手順

```bash
# ECR削除
aws ecr batch-delete-image --repository-name dev-web-app \
  --image-ids "$(aws ecr list-images --repository-name dev-web-app --query 'imageIds' --output json)"

# S3削除（バージョン含む）
for bucket in dev-frontend-227811178732 dev-input-bucket-227811178732 dev-output-bucket-227811178732 dev-cloudtrail-227811178732; do
  aws s3 rm s3://$bucket --recursive
  aws s3api delete-objects --bucket $bucket \
    --delete "$(aws s3api list-object-versions --bucket $bucket \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null
  aws s3api delete-objects --bucket $bucket \
    --delete "$(aws s3api list-object-versions --bucket $bucket \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null
done

# BackupVault削除
RECOVERY_POINTS=$(aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name dev-backup-vault \
  --query "RecoveryPoints[*].RecoveryPointArn" --output text)
for arn in $RECOVERY_POINTS; do
  aws backup delete-recovery-point --backup-vault-name dev-backup-vault --recovery-point-arn $arn
done

# terraform destroy
cd ~/kazu-aws-full-project/terraform/environments/dev
terraform destroy
```

## 14. トラブルシューティング

| エラー | 原因 | 対処 |
|---|---|---|
| 503 Service Unavailable | ECSタスクが落ちている | aws ecs describe-servicesでイベント確認 |
| KMS key access denied | ECSタスクロールにKMS権限がない | container/main.tfのecs_task_kmsを確認 |
| RequestTimeTooSkewed | WSLの時刻ズレ | sudo ntpdate pool.ntp.org |
| ECR Repository already exists | tfstateが空でECRが残っている | terraform import module.container.aws_ecr_repository.main dev-web-app |
| AUTH_FAILURE | RDS ProxyがSecretsManagerにアクセスできない | database/main.tfのrds_proxy_secrets_policyを確認 |
| 403 CloudFront（ファイルアップロード） | WAFのSizeRestrictions_BODYがブロック | cdn/main.tfでrule_action_overrideを確認 |
| Not authenticated（CloudFront経由） | AuthorizationヘッダーがCloudFrontで転送されていない | cdn/main.tfのforwarded_valuesにAuthorizationを追加 |
| User pool client does not exist | Cognito Client IDが古い | terraform output cognito_client_idで最新値確認 |
| dev-test-user-secret作成エラー | 削除待ち状態 | aws secretsmanager delete-secret --secret-id dev-test-user-secret --force-delete-without-recovery |
| ログイン後に黒画面 | ブラウザの自動翻訳がReactのDOMと競合 | index.htmlにtranslate="no"・notranslateを追加済み |
| Target group doesn't have read-only instances | Aurora単一インスタンスでReaderエンドポイントが使えない | database.pyでDATABASE_URL_WRITERにフォールバック済み |

## 15. 次の会話の始め方

新しい会話を始める時は以下をAIに伝えてください：

---
GitHubの以下のファイルを読んでから作業を始めてください：
https://github.com/o-kazuo/kazu-aws-full-project/blob/main/HANDOVER.md

このファイルがKazuAI Platformプロジェクトの引き継ぎ書です。
内容を把握した上で作業を続けてください。
---

