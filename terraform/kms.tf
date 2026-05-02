# KMSキーの作成
resource "aws_kms_key" "main" {
  description             = "Kazu AWS KMS Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "kazu-kms-key"
  }
}

# KMSキーのエイリアス（わかりやすい名前）
resource "aws_kms_alias" "main" {
  name          = "alias/kazu-main-key"
  target_key_id = aws_kms_key.main.key_id
}