# outputs.tf
output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.iss_telemetry_analyzer.arn
}


output "websocket_url" {
  value = aws_apigatewayv2_stage.websocket_stage.invoke_url
}
