# KazuAI Platform

本プロジェクトは**インフラ自動化・セキュリティ設計・CI/CDの実践習得**を主目的として構築したAWSフルスタック環境です。

アプリケーション自体は最小限のモック構成に留め、**Terraformによるインフラ完全コード化・GitHub ActionsによるCI/CD・WAF/KMS/IAM最小権限によるセキュリティ堅牢化**に重点を置いています。AIサービスはAWSマネージドサービスの統合・クロスリージョン設計の検証として組み込みました。

---

## 🎯 プロジェクト概要

| 項目 | 内容 |
|---|---|
| 目的 | 本番環境を想定したインフラ自動化・セキュリティ堅牢化・CI/CDの設計検証（アプリは最小限のモック構成） |
| 期間 | 約5ヶ月（AWS資格取得→コンソール構築→IaC・CI/CD実装） |
| 構成 | フロントエンド（React/Vite）+ バックエンド（FastAPI）+ AWS各種サービス |
| 認証 | Amazon CognitoによるJWT認証 |
| インフラ | Terraform完全管理・destroy→applyで完全復元可能 |

---

## 🏗️ アーキテクチャ

```mermaid
graph TB
    User["User"] -->|HTTPS| CF["CloudFront + WAF"]
    CF -->|"/api/*"| ALB["ALB"]
    CF -->|"/*"| S3F["S3 React/Vite"]
    ALB --> ECS["ECS Fargate FastAPI"]
    ECS --> Cognito["Cognito JWT"]
    ECS --> Proxy["RDS Proxy"]
    Proxy --> Aurora["Aurora MySQL 8.0"]
    ECS --> S3I["S3 input"]
    S3I -->|"images/"| Lambda["Lambda"]
    Lambda --> Rekognition["Rekognition"]
    Lambda --> DynamoDB["DynamoDB"]
    Lambda --> SNS["SNS"]
    ECS --> Bedrock["Bedrock Claude"]
    ECS --> Transcribe["Transcribe"]
    ECS --> Translate["Translate"]
    ECS --> Comprehend["Comprehend"]
    ECS --> Textract["Textract us-east-1"]
    CloudTrail["CloudTrail"] --> S3CT["S3 audit"]
    style CF fill:#FF9900,color:#fff
    style ECS fill:#FF9900,color:#fff
    style Aurora fill:#3F8624,color:#fff
    style Bedrock fill:#7B2FBE,color:#fff
```

### クロスリージョン設計
TextractはTokyoリージョン（ap-northeast-1）未対応のため、us-east-1にS3バケットを作成してクロスリージョンアクセスを実現。

> ※ 図中のCloudTrailはユーザーの操作ではなく、AWS上の全API操作を自動で記録する監査サービスです。

---

## 🔒 セキュリティ設計

- **エッジ保護**：WAF v2でSQLi・XSS・DDoSをエッジで遮断
- **最小権限**：IAMロールによる最小権限設計・OIDC認証でアクセスキー不要
- **全リソース暗号化**：KMSによりS3・RDS・DynamoDB・SecretsManagerの全データを暗号化。鍵のポリシーも特定ARNに絞り込んだ最小権限設計
- **閉域通信の徹底**：S3・DynamoDBへのVPCゲートウェイエンドポイントを設置し、インターネットを経由しない内部ネットワーク通信を実現。セキュリティ向上とNATゲートウェイのコスト削減を同時に達成
- **シークレット管理**：Secrets ManagerでDB接続情報を管理・Terraform完全自動化
- **脅威検知**：GuardDutyによる機械学習ベースの異常検知
- **監査**：CloudTrailで全API操作を記録・専用S3バケットに保存
- **個人情報保護**：Macieによる個人情報（PII）検出

---

## 📈 主要な実装ポイント

### IaC完全管理
手動CLIでのインフラ変更は一切なし。Secrets Managerの値もTerraformで管理。destroy→applyで完全復元可能。

### CI/CD完全自動化
git pushのみでECRイメージビルド・DBマイグレーション・ECSデプロイ・フロントエンドビルド・S3デプロイ・CloudFrontキャッシュクリアまで自動実行。

### ECS AutoScaling
CPU使用率70%超えで自動スケールアウト（最小1・最大5タスク）、30%以下でスケールイン。CloudWatchアラームと連携。

### DB読み書き分離
RDS ProxyのWriter・Readerエンドポイントを分離。FastAPIの書き込み処理はWriter、読み込み処理はReaderに振り分け。
※現在は開発環境のためAurora Serverless v2を単一インスタンスで運用。本番環境ではReaderインスタンスを追加して完全な読み書き分離を実現。

### クロスリージョン設計
TextractはTokyoリージョン未対応のため、us-east-1にS3バケットを作成。ECSタスクがap-northeast-1からus-east-1のS3・Textractにクロスリージョンアクセスする設計を実装。

### DB接続安定化
Aurora Serverless v2とRDS Proxyの組み合わせで発生する接続切れを、pool_recycle・pool_pre_pingの設定で解決。

---

## 🤖 実装したAIサービス連携

| サービス | 機能 |
|---|---|
| Amazon Bedrock（Claude Haiku 4.5） | テキスト生成・文書要約・感情分析 |
| Amazon Rekognition | 画像ラベル検出・顔検出・感情推定・年齢推定 |
| Amazon Transcribe | 音声ファイル→テキスト変換（日本語・英語・中国語・韓国語） |
| Amazon Translate | 多言語翻訳（日・英・中・韓・仏・独） |
| Amazon Comprehend | テキスト感情分析・エンティティ抽出・キーフレーズ検出 |
| Amazon Textract | PDF・画像からのテキスト抽出・フォーム解析（クロスリージョン設計） |
| Amazon Macie | 個人情報（PII）検出 |

---

## 🔥 苦労したこと・気づいたこと

**SGルールの設定**
セキュリティグループのegressブロックとaws_security_group_ruleを混在させるとTerraformが競合してエラーになることを学びました。どちらか一方に統一することで解決しました。

**KMSの依存関係**
他のリソースの設定を変更するたびにKMSのポリシーが影響を受け、権限エラーが連鎖することがありました。IAMとKMSの依存関係を意識した設計の重要性を実感しました。

**WAF導入時のReact通信ブロック**
WAF導入後にReactフロントエンドからのAPI通信がブロックされる事象が発生。CloudWatchのWAFログを解析し、誤検知ルールを特定してルール最適化を実施。ログ駆動のトラブルシューティングを実践しました。

**GitHub ActionsのOIDC認証デバッグ**
IAM最小権限設計（特定ARN絞り込み）の実装時、OIDC認証でのアクセス権限エラーが発生。ポリシーのARN条件を段階的に絞り込みながらデバッグし、最終的に必要最小限の権限のみで動作する構成を実現しました。

**destroyを前提とした自動化**
コスト削減のために毎回terraform destroyをするため、手動作業が残っていると復元のたびに詰まります。この経験から「全ての作業をコードで自動化する」ことの重要性を身をもって学びました。結果としてIaC完全管理・CI/CD自動化・SecretsManager自動化まで徹底できました。

**コスト最適化への気づき**
S3・DynamoDBへのVPCゲートウェイエンドポイントは自分で気づいて追加しました。インターネットを経由しないことでセキュリティとコストを同時に改善できる点が面白かったです。

---

## 📊 Well-Architected Framework への対応

| 柱 | 実装内容 |
|---|---|
| 運用上の優秀性 | IaC完全管理・CI/CD自動化・CloudWatch監視ダッシュボード |
| セキュリティ | KMS・WAF・GuardDuty・Cognito・OIDC・最小権限IAM・Macie |
| 信頼性 | マルチAZ・ECS AutoScaling・AWS Backup・DB接続プール最適化 |
| パフォーマンス効率 | CloudFront・Aurora Serverless v2・Fargate・DB読み書き分離・クロスリージョン設計 |
| コスト最適化 | Serverless・Budgets・destroy運用・VPCエンドポイント |

---

## 💰 コスト設計

- **開発時**：作業後にterraform destroyでコスト最小化
- **Budgetsアラート**：月次予算超過時にメール通知
- **Serverless活用**：Aurora Serverless v2・Lambda・Fargateで使った分だけ課金

---

## 🚀 デプロイ手順

### 前提条件
- AWS CLI設定済み（AdministratorAccess）
- Terraform インストール済み
- WSL（Ubuntu）環境

### 手順
1. リポジトリクローン
2. 時刻同期（WSL必須）: `sudo ntpdate pool.ntp.org`
3. バックエンド作成（初回のみ）: `cd terraform/backend && terraform init && terraform apply`
4. 環境デプロイ: `cd ../environments/dev && terraform init && terraform apply`
5. アプリデプロイ（GitHub Actionsが自動実行）: `git push origin main`
6. 削除前の準備: ECR・S3・BackupVaultを先に空にしてから `terraform destroy`

---

## 🔮 今後の予定

- Aurora Readerインスタンス追加による完全な読み書き分離
- Amazon Athenaによるログ分析基盤の構築

---

## 👤 Author

**K.Nishikawa**
- GitHub：[@o-kazuo](https://github.com/o-kazuo)
- 学習期間：約5ヶ月（AWS資格取得→コンソール構築→IaC・CI/CD実装）
- 取得資格：AWS Cloud Practitioner / AWS Solutions Architect Associate
