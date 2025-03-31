variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub username or organization that owns the repository"
  type        = string
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Amount of memory in MB for Lambda function"
  type        = number
  default     = 128
}

variable "kinesis_arn" {
  description = "ARN of the Kinesis stream"
  type        = string
}