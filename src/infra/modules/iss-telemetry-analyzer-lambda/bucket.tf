# S3 bucket to store the Lambda package
#resource "aws_s3_bucket" "lambda_bucket" {
 # bucket = "iss-telemetry-analyzer-lambda"
#}

# Upload the zip to S3
#resource "aws_s3_object" "lambda_package" {
 # bucket = "iss-telemetry-analyzer-lambda"
# key    = "iss-telemetry-analyzer.zip"
# }