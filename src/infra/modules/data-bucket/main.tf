resource "aws_s3_bucket" "iss-historical-data" {
  bucket = "iss-historical-data"
  force_destroy = true  # This ensures all objects are deleted before bucket removal

  tags = {
    Name  = "iss-historical-data"
  }

}
