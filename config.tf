## Enable AWS Config

resource "aws_config_configuration_recorder" "config" {
  name     = lower("zimperium-${terraform.workspace}-config")
  role_arn = aws_iam_role.role.arn
}

## Create IAM Role for AWS config

resource "aws_iam_role" "role" {
  name = lower("zimperium-${terraform.workspace}-config-role")

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "policy" {
  name = lower("zimperium-${terraform.workspace}-config-policy")
  role = aws_iam_role.role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "config:Put*",
          "Effect": "Allow",
          "Resource": "*"

      }
  ]
}
POLICY
}