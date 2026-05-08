# KazuAI Platform 引き継ぎ書
## Phase N 更新版（2026年5月8日更新）

## ⚠️ 絶対ルール
- AWSリソースの変更は全部Terraformから！手動CLIでの変更は絶対NG
- 機密情報はSecretsManagerで管理！GitHubへの露出は絶対NG
- 全作業はWSLで統一！PowerShellとの混在はNG
- 場当たり的な修正は絶対にしない！根本原因を特定してから修正する！
- terraform planで確認 → terraform applyで実行の順番を守る
- 確認系コマンド（describe・logs・curl）はCLI直接でOK

## 1. 現在の状態
| コンポーネント | 状態 | 備考 |
|---|---|---|
| インフラ（Terraform） | ✅ 完了 | 全手動作業を自動化済み |
| バックエンド（FastAPI） | ✅ 動作確認済み | ECS Fargate・/api/healthで確認済み |
| CI/CD（GitHub Actions） | ✅ 完了 | OIDC認証・アクセスキー不要 |
| SecretsManager連携 | ✅ 完了 | RDS Proxy用とアプリ用に分離 |
| フロントエンド（React/Vite） | ✅ 完了 | CloudFront経由でHTTPS配信 |
| CloudFront | ✅ 完了 | S3オリジン追加・OAC設定済み |
| RDS Proxy | ✅ 完了 | caching_sha2_passwordで統一 |
| WAF | ✅ 完了 | SQLi・一般攻撃対策済み |
| IAM最小権限 | ✅ 完了 | OIDC認証に移行・アクセスキー廃止 |
| WSL統一環境 | ✅ 完了 | 2026年5月6日に対応済み |
| Lambda（画像処理） | ✅ 完了 | Rekognition・DynamoDB連携済み |
| CloudTrail専用バケット | ✅ 完了 | inputバケットから分離済み |
| SGルール管理 | ✅ 完了 | egress競合修正済み |
| DynamoDB APIエンドポイント | ✅ 完了 | GET /api/ai/image-analysis追加済み |
| ECSタスクロール権限 | ✅ 完了 | DynamoDB・KMS権限追加済み（Terraform済み） |
| Cognito認証 | ✅ 動作確認済み | テストユーザー作成済み |
| Alembicマイグレーション | ⚠️ 未完了 | 明日実装（下記参照） |
| ai_resultsテーブル構造 | ⚠️ 未完了 | マイグレーション待ち |
| フロントエンドUI | ⏳ 未着手 | 画像アップロード・Rekognition結果表示 |
| CloudWatch監視ダッシュボード | ⏳ 未着手 | Lambda・ECS・RDS監視強化 |

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
| AWS Account ID | 227811178732 |
| AWS Region | ap-northeast-1 |
| DynamoDB（画像分析） | dev-image-analysis |
| Cognito User Pool ID | ap-northeast-1_ulq3dMQjE |
| Cognito Client ID | 37p85l0noeanb5d9h8884adh12 |
| テストユーザー | hokkaido.nan@gmail.com / Kazu6187! |

### applyのたびに変わる値
| 項目 | 確認コマンド |
|---|---|
| ALB DNS | `aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text` |
| Lex Bot ID | terraform applyのOutputsを確認 |
| CloudFront URL | `terraform output cloudfront_domain_name` |
| GitHub Actions Role ARN | `terraform output github_actions_role_arn` |

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

### Step 3: GitHub Secrets確認
```bash
terraform output github_actions_role_arn
```

### Step 4: デプロイ
```bash
cd ~/kazu-aws-full-project
git commit --allow-empty -m "ci: trigger deploy"
git push origin main
```

### Step 5: 動作確認
```bash
ALB_DNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text)
curl http://$ALB_DNS/api/health

TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 37p85l0noeanb5d9h8884adh12 \
  --auth-parameters USERNAME=hokkaido.nan@gmail.com,PASSWORD="Kazu6187!" \
  --query "AuthenticationResult.AccessToken" \
  --output text)
curl -H "Authorization: Bearer $TOKEN" http://$ALB_DNS/api/ai/image-analysis
```

## 5. 未解決の問題（最重要・明日対応）

### Alembicマイグレーションが動かない
**根本原因：RDS ProxyはDDL非対応**

**正しい解決策：マイグレーション専用ECSタスクをGitHub Actionsから起動**
GitHub Actions

ECRにイメージビルド・プッシュ
マイグレーション専用ECSタスク起動（Aurora直接接続・DDL実行）
タスク完了を待機
ECSサービスデプロイ（RDS Proxy経由・通常運用）


**明日の実装手順：**
1. database/main.tfにECS→Aurora SGルール追加（Terraform）
2. container/main.tfにマイグレーション専用タスク定義追加（Terraform）
3. deploy.ymlにマイグレーションステップ追加（GitHub Actions）
4. app/main.pyのstartupをcreate_all()に戻す
5. terraform apply → push → 動作確認

**⚠️ 明日最初にやること：main.pyを修正してpush**
現在のままではデプロイ時にハングする！

```python
# 現在（NG）
from alembic.config import Config
from alembic import command
@app.on_event("startup")
def startup():
    alembic_cfg = Config("/app/alembic.ini")
    alembic_cfg.set_main_option("script_location", "/app/migrations")
    command.upgrade(alembic_cfg, "head")

# 明日最初に戻すべき姿
@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
```

## 6. Terraformモジュール構成
terraform/modules/
networking/  database/  security/  compute/  serverless/
monitoring/  backup/    cdn/       lex/      container/
auth/        messaging/ governance/ cache/   batch/

### モジュール依存関係
networking → database → security → compute → container

### 今日追加したTerraform変更（container/main.tf）
- DynamoDBアクセス権限（ECSタスクロール）
- KMSアクセス権限（ECSタスクロール）
- S3_BUCKET_NAME環境変数（ECSタスク定義）

## 7. SGルール管理
⚠️ egressブロックとaws_security_group_ruleを混在させない！

| ルール | 管理場所 |
|---|---|
| ECS → RDS Proxy（3306） | container/main.tf |
| RDS Proxy → Aurora（3306） | database/main.tf |

## 8. SecretsManager構成
| Secret名 | 用途 | KMS暗号化 |
|---|---|---|
| dev-db-secret-proxy | RDS ProxyがAuroraに接続 | なし |
| dev-app-secret | アプリがRDS Proxyに接続 | あり |

## 9. Lambda（画像処理）構成
| 項目 | 値 |
|---|---|
| 関数名 | dev-image-resize |
| ランタイム | Python 3.11 |
| メモリ | 512MB |
| タイムアウト | 60秒 |
| トリガー | S3（images/プレフィックスのみ） |

### ZIPの再作成方法
```bash
mkdir -p ~/lambda_build/package && cd ~/lambda_build
pip install pillow boto3 \
  --target ./package \
  --platform manylinux2014_x86_64 \
  --python-version 3.11 \
  --only-binary=:all: \
  --break-system-packages
cp ~/kazu-aws-full-project/package/lambda_function.py ~/lambda_build/package/
cd ~/lambda_build/package
zip -r ~/kazu-aws-full-project/package/lambda_function.zip .
```

## 10. destroy前の手順
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

## 11. トラブルシューティング
| エラー | 原因 | 対処 |
|---|---|---|
| 503 Service Unavailable | ECSタスクが落ちている | `aws ecs describe-services`でイベント確認 |
| Waiting for application startup（ハング） | main.pyにAlembicが残っている | create_all()に戻してpush |
| KMS key access denied | ECSタスクロールにKMS権限がない | container/main.tfのecs_task_kmsを確認 |
| Invalid bucket name "" | S3_BUCKET_NAME環境変数がない | container/main.tfのenvironmentを確認 |
| RequestTimeTooSkewed | WSLの時刻ズレ | `sudo ntpdate pool.ntp.org` |
| Error acquiring the state lock | terraform操作が中断 | DynamoDBのロックを削除 |
| ECR Repository already exists | tfstateが空でECRが残っている | `terraform import module.container.aws_ecr_repository.main dev-web-app` |
| AUTH_FAILURE | RDS ProxyがSecretsManagerにアクセスできない | database/main.tfのrds_proxy_secrets_policyを確認 |

## 12. これからやること

### 最優先（明日最初）
| # | タスク |
|---|---|
| 0 | main.pyのstartupをcreate_all()に戻す→push |
| 1 | Alembicマイグレーション専用ECSタスク実装（Terraform+GitHub Actions） |
| 2 | /api/ai/upload動作確認 |

### 高優先度
| # | タスク |
|---|---|
| 3 | フロントエンドUI（画像アップロード・Rekognition結果表示） |
| 4 | CloudWatch監視ダッシュボード |

### 技術的負債
| # | タスク |
|---|---|
| 5 | uvicornログレベルをdebugから戻す（app/Dockerfile） |
| 6 | boto3をLambda ZIPから除外（サイズ削減） |
| 7 | KMSポリシーのResource:*を特定ARNに絞る |
| 8 | ALBのHTTPS化（ドメイン取得後） |
| 9 | 読み書き分離（WRITER/READER） |
| 10 | IAMユーザーのMFA設定 |
| 11 | Node.jsの警告修正（20→24） |

---
作成日：2026年5月6日／最終更新：2026年5月8日
