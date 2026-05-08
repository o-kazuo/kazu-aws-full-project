#!/bin/bash
set -e

echo "=== KazuAI Platform 動作確認 ==="

# 変数取得
ALB_DNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text)
CLIENT_ID=$(cd ~/kazu-aws-full-project/terraform/environments/dev && terraform output -raw cognito_client_id)

# SecretsManagerからテストユーザー情報取得
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id dev-test-user-secret \
  --query SecretString \
  --output text)
USERNAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
PASSWORD=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

# ヘルスチェック
echo "--- ヘルスチェック ---"
curl -s http://$ALB_DNS/api/health

# TOKEN取得
TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id $CLIENT_ID \
  --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD \
  --query "AuthenticationResult.AccessToken" \
  --output text)

# API確認
echo "--- image-analysis ---"
curl -s -H "Authorization: Bearer $TOKEN" http://$ALB_DNS/api/ai/image-analysis

echo ""
echo "=== 確認完了 ==="
