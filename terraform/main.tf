# Add the resources related to the provider

# S3 bucket for hosting app
## Enabled ACL for Public Access
# Cloudfront
# S3 bucket for logs

resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "static-website-${var.environment}-${local.account_id}"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "static-website-logs-${var.environment}-${local.account_id}"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "static_bucket_ownership" {
  bucket = aws_s3_bucket.static_website_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [ 
    aws_s3_bucket.static_website_bucket
   ]
}

resource "aws_s3_bucket_ownership_controls" "logging_access_bucket_ownership" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [ 
    aws_s3_bucket.access_logs_bucket
   ]
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.static_website_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.static_website_bucket.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.static_bucket_ownership,
    aws_s3_bucket_public_access_block.public_access
  ]
}

resource "aws_s3_bucket_acl" "access_logs_bucket_acl" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  access_control_policy {
    grant {
      grantee {
        id = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
  depends_on = [ 
    aws_s3_bucket_ownership_controls.logging_access_bucket_ownership
   ]
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.static_website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.static_website_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled = true

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.access_logs_bucket.bucket_regional_domain_name
    prefix          = "logs/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [ 
    aws_s3_bucket.access_logs_bucket
  ]
}

