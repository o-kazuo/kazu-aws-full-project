# KazuAI Platform 引き継ぎ書
## Phase N+1 更新版（2026年5月9日更新）

## ⚠️ 絶対ルール
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
| SecretsManager連携 | ✅ 完了 | RDS Proxy用とアプリ用に分離 |
| フロントエンド（React/Vite） | ✅ 完了 | CloudFront経由でHTTPS配信 |
| CloudFront | ✅ 完了 | Authorizationヘッダー転送設定済み |
| RDS Proxy | ✅ 完了 | caching_sha2_passwordで統一 |
| WAF | ✅ 完了 | SQLi・一般攻撃対策・SizeRestrictions_BODY除外済み |
| IAM最小権限 | ✅ 完了 | OIDC認証に移行・アクセスキー廃止 |
| WSL統一環境 | ✅ 完了 | 2026年5月6日に対応済み |
| Lambda（画像処理） | ✅ 完了 | Rekognition・DynamoDB連携済み |
| CloudTrail専用バケット | ✅ 完了 | inputバケットから分離済み |
| SGルール管理 | ✅ 完了 | egress競合修正済み |
| DynamoDB APIエンドポイント | ✅ 完了 | GET /api/ai/image-analysis追加済み |
| ECSタスクロール権限 | ✅ 完了 | S3・Rekognition・Cognito・DynamoDB・KMS権限追加済み |
| Cognito認証 | ✅ 動作確認済み | terraform output・SecretsManagerで自動化済み |
| Alembicマイグレーション | ✅ 完了 | 専用ECSタスク・GitHub Actions自動化済み |
| /api/ai/upload | ✅ 動作確認済み | CloudFront経由でファイルアップロード確認済み |
| /api/ai/results | ✅ 動作確認済み | CloudFront経由でDB結果取得確認済み |
| フロントエンドUI | ✅ 完了 | Rekognition結果ビジュアル表示（信頼度バー・顔検出） |
| 動作確認スクリプト | ✅ 完了 | scripts/verify.sh（SecretsManager連携） |
| ECS AutoScaling | ⏳ 未着手 | 次のタスク |
| CloudWatch監視ダッシュボード | ⏳ 未着手 | AutoScalingと一緒に実装 |

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
| ALB DNS | `aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text` |
| Lex Bot ID | `terraform output lex_bot_id` |
| CloudFront URL | `terraform output cloudfront_domain_name` |
| GitHub Actions Role ARN | `terraform output github_actions_role_arn` |
| Cognito User Pool ID | `terraform output cognito_user_pool_id` |
| Cognito Client ID | `terraform output cognito_client_id` |

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

### Step 4: 動作確認（自動スクリプト）
```bash
~/kazu-aws-full-project/scripts/verify.sh
```

## 5. 次にやること（最優先）

### ECS AutoScaling + CloudWatch監視ダッシュボード（セットで実装）
**実装場所：terraform/modules/container/main.tf と terraform/modules/monitoring/main.tf**

#### ECS AutoScaling実装手順
1. container/main.tfに以下を追加：
   - aws_appautoscaling_target（最小1・最大5タスク）
   - aws_appautoscaling_policy（CPU 70%でスケールアウト・30%でスケールイン）

#### CloudWatchダッシュボード強化
monitoring/main.tfのダッシュボードにウィジェット追加：
- ECS CPU・メモリ使用率
- RDS CPU・接続数・レイテンシ
- Lambda エラー・実行時間・実行回数
- CloudFront キャッシュヒット率・リクエスト数
- WAF ブロック数
- DynamoDB 読み書きスロットリング
- ALBリクエスト数・5XXエラー（既存）

#### アラーム追加
- ECS CPU 70%超え → SNS通知
- ECS メモリ 80%超え → SNS通知
- Lambda エラー5件超え → SNS通知（既存）
- RDS接続数80超え → SNS通知（既存）

## 6. やることリスト（技術的負債）
| # | タスク | 内容 |
|---|---|---|
| 1 | ECS AutoScaling | CPU70%でスケールアウト・最小1・最大5タスク |
| 2 | CloudWatch監視ダッシュボード | ECS・ALB・RDS・Lambda・CloudFront・WAF・DynamoDB |
| 3 | Webページを綺麗にする | フロントエンドUIの改善・文字ズレ修正 |
| 4 | DBクエリ確認 | RDS・DynamoDBのデータをクエリして中身を確認 |
| 5 | 読み書き分離 | DATABASE_URL_WRITERとDATABASE_URL_READERに分けてRDS Proxyを活用 |
| 6 | IAMユーザーのMFA設定 | AWSコンソールへのMFAログイン設定 |
| 7 | Node.jsの警告修正 | GitHub ActionsのNode.js 20→24への対応 |
| 8 | ALBのHTTPS化 | ACM証明書を設定してHTTPSに対応（ドメイン取得後） |
| 9 | KMSポリシーの絞り込み | 現在Resource:*になっているKMSのIAM権限を特定ARNに絞る |
| 10 | RDSパスワード強化 | 強いパスワードに変更してSecretsManagerで管理 |
| 11 | boto3をLambdaから除外 | Lambda実行環境にboto3が含まれているためZIPサイズ削減可能 |
| 12 | uvicornログレベル戻す | app/DockerfileのログレベルをdebugからINFOに戻す |

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
| dev-app-secret | アプリがRDS Proxyに接続 | あり |
| dev-test-user-secret | テストユーザー情報（username/password） | あり |

## 10. Lambda（画像処理）構成
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

## 11. GitHub Actions（deploy.yml）フロー
git push → ECRにイメージビルド・プッシュ
        → マイグレーション専用ECSタスク起動（Aurora直接接続）
        → タスク完了待機・成功確認
        → ECSサービスデプロイ（RDS Proxy経由）
        → フロントエンドビルド・S3デプロイ

## 12. destroy前の手順
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

## 13. トラブルシューティング
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
| 403 CloudFront（ファイルアップロード） | WAFのSizeRestrictions_BODYがブロック | cdn/main.tfでrule_action_overrideを確認 |
| Not authenticated（CloudFront経由） | AuthorizationヘッダーがCloudFrontで転送されていない | cdn/main.tfのforwarded_valuesにAuthorizationを追加 |
| User pool client does not exist | Cognito Client IDが古い | `terraform output cognito_client_id`で最新値確認 |
| InvalidImageFormatException | 画像フォーマット問題 | `convert -strip`でExif除去してリトライ |

---
作成日：2026年5月6日／最終更新：2026年5月9日
