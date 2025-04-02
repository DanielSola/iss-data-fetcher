resource "aws_dynamodb_table" "websocket_connections" {
  name         = "WebSocketConnections"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "connectionId"
    type = "S"
  }

  hash_key = "connectionId"

  tags = {
    Name        = "WebSocketConnections"
    Environment = "production"
  }
}