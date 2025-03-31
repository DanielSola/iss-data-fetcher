resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = var.kinesis_arn  # Reference the existing stream
  function_name     = aws_lambda_function.iss_telemetry_analyzer.arn
  starting_position = "LATEST"
  batch_size        = 1  # Adjust batch size as needed
}