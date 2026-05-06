output "sqs_queue_url" {
  description = "SQSキューURL"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "SQSキューARN"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "デッドレターキューURL"
  value       = aws_sqs_queue.dlq.url
}