resource "aws_iam_policy" "kinesis_policy" {
  name        = "KinesisWritePolicy"
  description = "Allows writing to Kinesis"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "kinesis:PutRecord"
      Resource = "arn:aws:kinesis:eu-west-1:730335312484:stream/iss-data-stream"
    }]
  })
}
