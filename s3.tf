resource "aws_s3_bucket" "bucket" {
  bucket = "insecure_bucket"
  acl    = "public-read"
}