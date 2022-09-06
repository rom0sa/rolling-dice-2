resource "aws_api_gateway_rest_api" "apigw_rest_api" {
  name = var.apigw_rest_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


resource "aws_api_gateway_resource" "apigw_rest_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
  parent_id   = aws_api_gateway_rest_api.apigw_rest_api.root_resource_id
  path_part   = var.apigw_rest_resource_path
}

resource "aws_api_gateway_method" "apigw_rest_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_rest_api_resource.id
  http_method   = var.apigw_rest_http_method
  request_validator_id = aws_api_gateway_request_validator.apigw_request_validator.id
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = false
    "method.request.querystring.rollCount" = false
    "method.request.querystring.dieCount" = false
    "method.request.querystring.dieSidesCount" = false
  }
}

resource "aws_api_gateway_method_response" "apigw_response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id = aws_api_gateway_resource.apigw_rest_api_resource.id
  http_method = aws_api_gateway_method.apigw_rest_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}
resource "aws_api_gateway_integration" "apigw_rest_integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id             = aws_api_gateway_resource.apigw_rest_api_resource.id
  http_method             = aws_api_gateway_method.apigw_rest_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.lambda_dice_roll.invoke_arn
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = <<EOF
##  See http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
##  This template will pass through all parameters including path, querystring, header, stage variables, and context through to the integration endpoint via the body/payload
#set($allParams = $input.params())
{
"body-json" : $input.json('$'),
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "apigw_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id = aws_api_gateway_resource.apigw_rest_api_resource.id
  http_method = aws_api_gateway_method.apigw_rest_method.http_method
  status_code = aws_api_gateway_method_response.apigw_response_200.status_code
  depends_on = [
    aws_api_gateway_integration.apigw_rest_integration
  ]
}

resource "aws_api_gateway_request_validator" "apigw_request_validator" {
  name                        = "apigw-rest-api-validator"
  rest_api_id                 = aws_api_gateway_rest_api.apigw_rest_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_dice_roll.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.apigw_rest_api.id}/*/${aws_api_gateway_method.apigw_rest_method.http_method}${aws_api_gateway_resource.apigw_rest_api_resource.path}"
}


resource "aws_api_gateway_deployment" "apigw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.apigw_rest_api_resource.id,
      aws_api_gateway_method.apigw_rest_method.id,
      aws_api_gateway_integration.apigw_rest_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "apigw_staging" {
  deployment_id = aws_api_gateway_deployment.apigw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  stage_name    = "v1"
}

output "api_invoke_url" {
  value = aws_api_gateway_stage.apigw_staging.invoke_url
  
}