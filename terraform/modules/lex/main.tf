# ===== Amazon Lex v2 =====

# IAM Role for Lex
resource "aws_iam_role" "lex_role" {
  name = "${var.env}-lex-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lexv2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lex_policy" {
  name = "${var.env}-lex-policy"
  role = aws_iam_role.lex_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["polly:SynthesizeSpeech"]
        Resource = "*"
      }
    ]
  })
}

# Lex v2 Bot
resource "aws_lexv2models_bot" "this" {
  name     = "${var.env}-kazu-bot"
  role_arn = aws_iam_role.lex_role.arn

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300

  tags = {
    Environment = var.env
  }
}

# Bot Locale (ja_JP)
resource "aws_lexv2models_bot_locale" "ja" {
  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = "ja_JP"

  n_lu_intent_confidence_threshold = 0.70
}

# ---- Intents ----

# 1. AIサービス案内
resource "aws_lexv2models_intent" "ai_guide" {
  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.ja.locale_id
  name        = "AIGuideIntent"
  description = "AIサービスの使い方を案内する"

  sample_utterance { utterance = "AIサービスを教えて" }
  sample_utterance { utterance = "何ができるの" }
  sample_utterance { utterance = "機能一覧" }
  sample_utterance { utterance = "使い方を教えて" }

  closing_setting {
    active = true
    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "KazuAIでは以下のAIサービスが使えます：\n1. 画像分析（Rekognition）\n2. 音声認識（Transcribe）\n3. 翻訳（Translate）\n4. テキスト分析（Comprehend）\n5. 文書抽出（Textract）\n6. 生成AI（Bedrock）\n7. PII検出（Macie）\n\n詳しく知りたいサービスはありますか？"
          }
        }
      }
    }
  }
}

# 2. 使用回数確認
resource "aws_lexv2models_intent" "usage_check" {
  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.ja.locale_id
  name        = "UsageCheckIntent"
  description = "使用回数を確認する"

  sample_utterance { utterance = "使用回数を確認したい" }
  sample_utterance { utterance = "あと何回使える" }
  sample_utterance { utterance = "残り回数" }
  sample_utterance { utterance = "使用状況" }

  closing_setting {
    active = true
    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "使用回数はダッシュボードで確認できます。各AIサービスは月10回まで無料で利用できます。"
          }
        }
      }
    }
  }
}

# 3. バッチジョブ案内
resource "aws_lexv2models_intent" "batch_guide" {
  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.ja.locale_id
  name        = "BatchGuideIntent"
  description = "バッチ処理の使い方を案内する"

  sample_utterance { utterance = "バッチ処理を使いたい" }
  sample_utterance { utterance = "大量処理したい" }
  sample_utterance { utterance = "バッチジョブ" }

  closing_setting {
    active = true
    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "AWS Batchを使った大量処理が可能です。APIの /batch/submit エンドポイントにジョブを投入してください。処理状況は /batch/status/{job_id} で確認できます。"
          }
        }
      }
    }
  }
}

# Bot Version
resource "aws_lexv2models_bot_version" "this" {
  bot_id = aws_lexv2models_bot.this.id

  locale_specification = {
    "ja_JP" = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_intent.ai_guide,
    aws_lexv2models_intent.usage_check,
    aws_lexv2models_intent.batch_guide,
  ]
}

