resource "aws_cloudformation_stack" "lambda_permissions" {
  name = "${var.name}-lambda-permissions-${aws_api_gateway_rest_api.this.id}"
  template_body = jsonencode({
    Resources = merge([
      for urlPath, config in local.definition : {
        for httpMethod, definition in config : "AllowExecutionFromAPIGateway${substr(sha256("${upper(httpMethod)} ${urlPath}  "), 0, 8)}" => {
          Type = "AWS::Lambda::Permission"
          Properties = {
            FunctionName = definition.lambda.function_name
            Action       = "lambda:InvokeFunction"
            Principal    = "apigateway.amazonaws.com"

            #   # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
            SourceArn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${upper(httpMethod)}${urlPath}"
          }
        }
      }
    ]...)
  })
}
