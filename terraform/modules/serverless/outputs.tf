output "input_bucket_name" {
  description = "S3入力バケット名"
  value       = aws_s3_bucket.input.bucket
}

output "output_bucket_name" {
  description = "S3出力バケット名"
  value       = aws_s3_bucket.output.bucket
}

output "sns_topic_arn" {
  description = "SNSトピックARN"
  value       = aws_sns_topic.notification.arn
}

output "lambda_function_name" {
  description = "Lambda関数名"
  value       = aws_lambda_function.image_resize.function_name
}
output "frontend_bucket_name" {
  description = "フロントエンドS3バケット名"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_regional_domain_name" {
  description = "フロントエンドS3バケットのリージョナルドメイン名"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_bucket_arn" {
  description = "フロントエンドS3バケットARN"
  value       = aws_s3_bucket.frontend.arn
}
