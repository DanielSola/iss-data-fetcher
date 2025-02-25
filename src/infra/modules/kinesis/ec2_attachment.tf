resource "aws_iam_role_policy_attachment" "attach_kinesis_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.kinesis_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}
