// get current aws account
data "aws_caller_identity" "current" {}

locals {
  principal_arns = var.principal_arns != null ? var.principal_arns : [data.aws_caller_identity.current.arn]
}

// Create policy

// let the provided principals or current account to assume roles
// all of this roles need to store, and lock the state file

// this aws_iam_policy_document is Terraform concept, not AWS's
// it let you specify JSON-formatted policy
data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_bucket.arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
  }

  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.dynamodb_table.arn]
  }

  statement {
    actions   = ["kms:*"]
    resources = [aws_kms_key.kms_key.arn]
  }
}

resource "aws_iam_policy" "policy" {
  name   = "S3BackendPolicy"
  policy = data.aws_iam_policy_document.policy_doc.json
}

// Create role
resource "aws_iam_role" "iam_role" {
  name = "S3BackendRole"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
        "AWS": ${jsonencode(local.principal_arns)}
      },
      "Effect": "Allow"
      }
    ]
  }
  EOF
}

// Attach 
resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.policy.arn
}