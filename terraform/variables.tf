#Account 
variable "region" {}
variable "accountId" {}

#API GATEWAY
variable "apigw_rest_name" {}
variable "apigw_rest_resource_path" {}
variable "apigw_rest_http_method" {}

#Lambda
variable "function_name" {}

#IAM
variable "lambda_dice_2_role" {}
variable "lambda_dice_2_policy" {}
