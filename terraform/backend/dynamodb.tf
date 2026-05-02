# tfstate State Lock用DynamoDBテーブル
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "kazu-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "kazu-terraform-lock"
  }
}