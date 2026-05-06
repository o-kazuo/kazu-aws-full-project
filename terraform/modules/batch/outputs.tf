output "job_queue_arn"      { value = aws_batch_job_queue.this.arn }
output "job_queue_name"     { value = aws_batch_job_queue.this.name }
output "job_definition_arn" { value = aws_batch_job_definition.this.arn }
output "job_definition_name" { value = aws_batch_job_definition.this.name }