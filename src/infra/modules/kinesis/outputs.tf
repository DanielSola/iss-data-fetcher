output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "stream_arn" {
  value = aws_kinesis_stream.iss_data_stream.arn
}

output "stream_name" {
  value = aws_kinesis_stream.iss_data_stream.name
}