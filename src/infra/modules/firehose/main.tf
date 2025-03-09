resource "aws_kinesis_firehose_delivery_stream" "demo_delivery_stream" {
  name        = "${var.input_kinesis_stream_name}-delivery"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.destination_bucket_arn
    buffering_size = 5
    buffering_interval = 60
    file_extension = ".json"

    cloudwatch_logging_options {
     enabled         = true
     log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
     log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
   }
  }

  kinesis_source_configuration {
    kinesis_stream_arn  = var.input_kinesis_stream_arn
    role_arn            = aws_iam_role.firehose_role.arn
  }

  tags = {
    Product = "Demo"
  }
}

# 🔹 Create a CloudWatch Log Group
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name = "/aws/kinesisfirehose/${var.input_kinesis_stream_name}-delivery"
}

# 🔹 Create a CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "firehose-delivery-stream-logs"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}
