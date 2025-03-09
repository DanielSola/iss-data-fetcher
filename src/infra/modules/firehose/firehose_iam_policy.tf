resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_delivery_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams",
          "kinesis:ListTagsForStream",
          "kinesis:GetRecords"
        ]
        Resource = "arn:aws:kinesis:eu-west-1:730335312484:stream/iss-data-stream"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          var.destination_bucket_arn,
         "${var.destination_bucket_arn}/*"

        ]

        
      },
            {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.firehose_log_group.arn,
          "${aws_cloudwatch_log_group.firehose_log_group.arn}:*"
        ]
      }

    ]
  })
}
