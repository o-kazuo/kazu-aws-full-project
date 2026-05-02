output "user_pool_id" {
  description = "Cognito ユーザープールID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito ユーザープールクライアントID"
  value       = aws_cognito_user_pool_client.main.id
}

output "api_endpoint" {
  description = "API GatewayエンドポイントURL"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}