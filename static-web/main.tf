provider "aws" {
  profile = "default"
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_acl" {
    depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]
    bucket = aws_s3_bucket.bucket.id
    acl = "private"
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.policy_cloudfront_access.json
}   

data "aws_iam_policy_document" "policy_cloudfront_access" {
    statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

locals {
    s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "distribution" {
    origin {
        domain_name = aws_s3_bucket.bucket.bucket_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_control.origin_s3.id
        origin_id = local.s3_origin_id
    }

    enabled = true
    default_root_object = "index.html"
    # aliases = ["trucstaticsites.com", "wwww.trucstaticsites.com"]

    restrictions {
        geo_restriction {
        restriction_type = "whitelist"
        locations        = ["VN", "SG"]
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }
}

resource "aws_cloudfront_origin_access_control" "origin_s3" {
  name                              = var.origin_s3_id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

output "cloudfront" {
    value = {
        domain_name = aws_cloudfront_distribution.distribution.domain_name
    }
}