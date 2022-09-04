data "aws_iam_policy_document" "lambda_assume_role_policy"{
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    principals {
      type        = "Service"
      identifiers = ["dynamodb.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_dice_2_role
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_logging" {
  name        = var.lambda_dice_2_policy
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Sid": "Stmt1662252795276",
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}