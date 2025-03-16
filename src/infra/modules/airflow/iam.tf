resource "aws_iam_role" "airflow_role" {
  name = "airflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "airflow_s3_policy" {
  name        = "airflow-s3-policy"
  description = "Allows Airflow to access S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::airflow-iss-anomaly-detector",
          "arn:aws:s3:::airflow-iss-anomaly-detector/*"        ]
      }
    ]
  })
}

# Create the IAM Instance Profile
resource "aws_iam_instance_profile" "airflow_profile" {
  name = "airflow-instance-profile"
  role = aws_iam_role.airflow_role.name
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "airflow_s3_attach" {
  role       = aws_iam_role.airflow_role.name
  policy_arn = aws_iam_policy.airflow_s3_policy.arn
}
