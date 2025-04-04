data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.static_website_bucket.arn,
      "${aws_s3_bucket.static_website_bucket.arn}/*",
    ]
  }
}
