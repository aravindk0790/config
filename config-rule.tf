## Configure restricted-ssh AWS config rule

resource "aws_config_config_rule" "rule" {
  name = lower("zimperium-${terraform.workspace}-restricted-ssh")
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
  depends_on = [aws_config_configuration_recorder.config]
}

## Configure SSM Automation Role 

data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMAutomationRole"
}

resource "aws_iam_role" "ssm_role" {
  name               = lower("zimperium-${terraform.workspace}-ssm-automation")
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
}

## Configure the automatic remediation for restricted ssh rule

resource "aws_config_remediation_configuration" "remedy" {
  config_rule_name = aws_config_config_rule.rule.name
  resource_type    = "AWS::EC2::SecurityGroup"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-DisableIncomingSSHOnPort22"
  target_version   = "1"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.ssm_role.arn
  }
  automatic = true
  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 25
      error_percentage                     = 20
    }
  }
}
