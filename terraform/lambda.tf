data "archive_file" "python_lambda_package" {  
  type = "zip"  
  source_file = "../dice.py" 
  output_path = "dice.zip"
}

resource "aws_lambda_function" "lambda_dice_roll" {
        function_name = var.function_name
        filename      = "dice.zip"
        source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
        role          = aws_iam_role.lambda_role.arn
        runtime       = "python3.9"
        handler       = "dice.lambda_handler"
        timeout       = 60
        depends_on = [
          aws_iam_role_policy_attachment.lambda_logs,
          aws_cloudwatch_log_group.aws_lambda_cloudwatch_logger,
  ]
}

resource "aws_cloudwatch_log_group" "aws_lambda_cloudwatch_logger" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}


