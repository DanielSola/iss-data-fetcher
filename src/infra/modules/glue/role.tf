resource "aws_iam_role" "s3_read_role" {
  name = "s3-read-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"  # Change this based on your use case
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "S3ReadOnlyPolicy"
  description = "Allows read-only access to the iss-historical-data bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::iss-historical-data",
          "arn:aws:s3:::iss-historical-data/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.s3_read_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}