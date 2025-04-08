variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "websocket_url" {
  description = "WebSocket URL from the analyzer lambda"
  type        = string
}