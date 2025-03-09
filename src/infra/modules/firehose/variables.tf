variable "destination_bucket_name" {
  description = "Firehose destination bucket name"
  type        = string
}

variable "destination_bucket_arn" {
  description = "Firehose destination bucket ARN"
  type        = string
}

variable "input_kinesis_stream_arn" {
  description = "ARN of the input kinesis stream"
  type        = string
}

variable "input_kinesis_stream_name" {
  description = "ARN of the input kinesis stream"
  type        = string
}