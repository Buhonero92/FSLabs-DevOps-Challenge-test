# Define the output for the CloudFront URL
output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "The CloudFront URL for the static website."
}