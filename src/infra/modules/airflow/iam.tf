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

# S3 Access Policy
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
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::airflow-iss-anomaly-detector",
          "arn:aws:s3:::airflow-iss-anomaly-detector/*",
          "arn:aws:s3:::iss-historical-data",
          "arn:aws:s3:::iss-historical-data/*"
        ]
      }
    ]
  })
}

# Fixed SageMaker Access Policy
resource "aws_iam_policy" "airflow_sagemaker_policy" {
  name        = "airflow-sagemaker-policy"
  description = "Allows Airflow to manage SageMaker training jobs and access logs"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:ListTrainingJobs",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpoint",
          "sagemaker:UpdateEndpoint",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:DescribeModel",
          "sagemaker:DescribeEndpointConfig",
          "sagemaker:DescribeEndpoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::730335312484:role/service-role/AmazonSageMaker-ExecutionRole-20250317T121373"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-1:730335312484:log-group:/aws/sagemaker/TrainingJobs:*"
      }
    ]
  })
}

# Create the IAM Instance Profile
resource "aws_iam_instance_profile" "airflow_profile" {
  name = "airflow-instance-profile"
  role = aws_iam_role.airflow_role.name
}

# Attach the S3 Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "airflow_s3_attach" {
  role       = aws_iam_role.airflow_role.name
  policy_arn = aws_iam_policy.airflow_s3_policy.arn
}

# Attach the SageMaker Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "airflow_sagemaker_attach" {
  role       = aws_iam_role.airflow_role.name
  policy_arn = aws_iam_policy.airflow_sagemaker_policy.arn
}
