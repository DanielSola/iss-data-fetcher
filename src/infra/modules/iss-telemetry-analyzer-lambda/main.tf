resource "aws_lambda_function" "iss_telemetry_analyzer" {
  function_name = "iss-telemetry-analyzer-lambda"
  s3_bucket     = "iss-telemetry-analyzer-lambda"
  s3_key        = "iss-telemetry-analyzer.zip"
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  role          = aws_iam_role.lambda_role.arn
  source_code_hash = aws_s3_object.lambda_package.etag
  timeout     = var.timeout
  memory_size = var.memory_size

  depends_on = [aws_s3_object.lambda_package]
}


#data "aws_s3_object" "lambda_package" {
 # bucket = "iss-telemetry-analyzer-lambda"
 # key    = "iss-telemetry-analyzer.zip"
#}

# Create WebSocket API
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "iss-telemetry-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Create WebSocket Routes
resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "sendmessage_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "sendmessage"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.iss_telemetry_analyzer.invoke_arn
}

# Deploy API Gateway
resource "aws_apigatewayv2_deployment" "websocket_deployment" {
  api_id = aws_apigatewayv2_api.websocket_api.id

  depends_on = [
    aws_apigatewayv2_route.connect_route,
    aws_apigatewayv2_route.disconnect_route,
    aws_apigatewayv2_route.sendmessage_route
  ]
}

# Create a stage for WebSocket API
resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id        = aws_apigatewayv2_api.websocket_api.id
  name          = "prod"
  deployment_id = aws_apigatewayv2_deployment.websocket_deployment.id
}
