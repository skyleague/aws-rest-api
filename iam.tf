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

data "aws_iam_policy_document" "vpc_invoke" {
  count = var.endpoint_type == "PRIVATE" && !var.disable_rest_api_vpc_policy ? 1 : 0
  dynamic "statement" {
    for_each = var.stages
    content {
      # Deny everything NOT coming from the VPC
      effect = "Deny"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions   = ["execute-api:Invoke"]
      resources = ["execute-api:/${statement.value}/*/*"]
      condition {
        test     = "StringNotEquals"
        variable = "aws:sourceVpc"
        values   = [var.vpc_id]
      }
    }
  }
  dynamic "statement" {
    for_each = var.stages
    content {
      # Otherwise, allow invoking the API endpoints
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions   = ["execute-api:Invoke"]
      resources = ["execute-api:/${statement.value}/*/*"]
    }
  }
}
resource "aws_api_gateway_rest_api_policy" "vpc_invoke" {
  count       = var.endpoint_type == "PRIVATE" && !var.disable_rest_api_vpc_policy ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = data.aws_iam_policy_document.vpc_invoke[count.index].json

  lifecycle {
    precondition {
      condition     = var.endpoint_type != "PRIVATE" || var.vpc_id != null || var.disable_rest_api_vpc_policy
      error_message = "Missing vpc_id for endpoint_type=PRIVATE."
    }
  }
}
