resource "aws_iam_user" "telemetry_analyzer_user" {
    name = "telemetry-analyzer-user"
}

resource "aws_iam_policy" "telemetry_analyzer_policy" {
    name        = "telemetry-analyzer-policy"
    description = "Policy granting access to S3 for telemetry analyzer"
    policy      = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action   = [
                    "s3:ListBucket",
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                ],
                Effect   = "Allow",
                Resource = [
                    "arn:aws:s3:::iss-telemetry-analyzer",
                    "arn:aws:s3:::iss-telemetry-analyzer/*"
                ]
            }
        ]
    })
}

resource "aws_iam_user_policy_attachment" "telemetry_analyzer_user_policy_attachment" {
    user       = aws_iam_user.telemetry_analyzer_user.name
    policy_arn = aws_iam_policy.telemetry_analyzer_policy.arn
}

resource "aws_iam_access_key" "telemetry_analyzer_access_key" {
    user = aws_iam_user.telemetry_analyzer_user.name
}

resource "aws_iam_policy" "deploy_lambda_policy" {
  name        = "deploy_lambda_policy"
  description = "Policy for managing the iss-telemetry-analyzer-lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:ListTags",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetPolicy",
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:eu-west-1:730335312484:function:iss-telemetry-analyzer-lambda"
      },
{
    "Effect": "Allow",
    "Action": [
        "lambda:ListTags",
        "lambda:CreateEventSourceMapping",
        "lambda:GetEventSourceMapping",
        "lambda:UpdateEventSourceMapping",
        "lambda:DeleteEventSourceMapping"
    ],
    "Resource": "*"
}
    ]
  })
}


resource "aws_iam_policy" "deploy_telemetry_analyzer_lambda" {
  name        = "deploy_telemetry_analyzer_lambda"
  description = "Policy for managing the iss-telemetry-analyzer-lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectTagging",
                "s3:DeleteObject",
                "s3:ListBucket"
        ],
        "Resource": [
                "arn:aws:s3:::iss-telemetry-analyzer-lambda",
                "arn:aws:s3:::iss-telemetry-analyzer-lambda/*"
            ]      }
    ]
  })
}

resource "aws_iam_policy" "handle_tf_state" {
  name        = "handle_tf_state"
  description = "Policy handling terraform state"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
				"s3:PutObject",
				"s3:GetObject",
				"s3:DeleteObject"
        ],
 			"Resource": "arn:aws:s3:::real-time-anomaly-detection-iss-terraform-state/terraform/state.tfstate"
    }
    ]
  })
}

resource "aws_iam_policy" "handle_websocket_connections_table" {
  name        = "handle_websocket_connections_table"
  description = "Policy handling websocket connection table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
				"dynamoDB:CreateTable",
				"dynamoDB:DeleteTable",
        "dynamoDB:TagResource",
        "dynamoDB:DescribeTable",
        "dynamoDB:DescribeContinuousBackups",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource"
        ],
 			"Resource": "arn:aws:dynamodb:eu-west-1:730335312484:table/WebSocketConnections"
    }
    ]
  })
}