resource "aws_iam_user" "telemetry_analyzer_user" {
    name = "telemetry-analyzer-user"
}

resource "aws_iam_policy" "telemetry_analyzer_policy" {
    name        = "telemetry-analyzer-policy"
    description = "Policy granting access to S3 for telemetry analyzer"
    policy      = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action   = [
                    "s3:ListBucket",
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                ],
                Effect   = "Allow",
                Resource = [
                    "arn:aws:s3:::iss-telemetry-analyzer",
                    "arn:aws:s3:::iss-telemetry-analyzer/*"
                ]
            }
        ]
    })
}

resource "aws_iam_user_policy_attachment" "telemetry_analyzer_user_policy_attachment" {
    user       = aws_iam_user.telemetry_analyzer_user.name
    policy_arn = aws_iam_policy.telemetry_analyzer_policy.arn
}

resource "aws_iam_access_key" "telemetry_analyzer_access_key" {
    user = aws_iam_user.telemetry_analyzer_user.name
}