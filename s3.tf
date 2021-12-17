# S3 Config
resource "aws_s3_bucket" "wpt-archive" {
  bucket = "my-wpt-test-archive-${random_string.bucket.result}"
  acl    = "private"
}