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
      "Resource": "arn:aws:execute-api:eu-west-1:730335312484:d0loutlbuc/prod/POST/@connections/*"
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