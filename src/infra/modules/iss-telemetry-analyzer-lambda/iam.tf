resource "aws_iam_role" "lambda_role" {
  name = "go_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS Lambda Basic Execution Role Policy
resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach the API Gateway Management permission for WebSocket connections
resource "aws_iam_policy" "lambda_websocket_management" {
  name        = "lambda-websocket-management-policy"
  description = "Allow Lambda to manage WebSocket connections"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "execute-api:ManageConnections",
      "Resource": "arn:aws:execute-api:eu-west-1:730335312484:*/prod/POST/@connections/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_websocket_management" {
  policy_arn = aws_iam_policy.lambda_websocket_management.arn
  role       = aws_iam_role.lambda_role.name
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iss_telemetry_analyzer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/*"
}


# Allow lambda to read kinesis stream
resource "aws_iam_policy" "lambda_kinesis_policy" {
  name        = "LambdaKinesisReadPolicy"
  description = "Allows Lambda to read from Kinesis Stream"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ]
        Resource = var.kinesis_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kinesis_attach" {
  policy_arn = aws_iam_policy.lambda_kinesis_policy.arn
  role       = aws_iam_role.lambda_role.name
}


# Access websocket connections table in DynamoDB
resource "aws_iam_policy" "websocket_dynamodb_policy" {
  name        = "WebSocketDynamoDBPolicy"
  description = "Policy to allow Lambda to manage WebSocket connections in DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.websocket_connections.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "websocket_lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.websocket_dynamodb_policy.arn
}


# Access websocket connections table in DynamoDB
resource "aws_iam_policy" "sagemaker_invoke_policy" {
  name        = "InvokePredictioEndpointPolicy"
  description = "Policy to allow Lambda to invoke prediction endpoint"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sagemaker:InvokeEndpoint",
        ]
        Resource = "arn:aws:sagemaker:eu-west-1:730335312484:endpoint/rcf-anomaly-predictor-endpoint"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sagemaker_invoke_policy.arn
}