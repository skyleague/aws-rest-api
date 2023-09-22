resource "aws_lambda_permission" "api_invoke" {
  for_each = merge([
    for http_path, path_items in var.definition : {
      for http_method, path_item in path_items : "${upper(http_method)} ${http_path}" => {
        function_name = path_item.lambda.function_name
        http_path     = http_path
        http_method   = http_method
      } if try(path_item.lambda, null) != null
    }
  ]...)

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn   = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.this.id}/*/${upper(each.value.http_method)}${each.value.http_path}"
  statement_id = "AllowExecutionFromAPIGateway${substr(sha256("${aws_api_gateway_rest_api.this.id} ${each.key}"), 0, 8)}"
}

resource "aws_lambda_permission" "authorizer_invoke" {
  for_each = merge([
    for http_path, path_items in var.definition : {
      for http_method, path_item in path_items : path_item.authorizer.name => {
        function_name = path_item.authorizer.lambda.function_name
      } if try(path_item.authorizer.lambda, null) != null
    }
  ]...)

  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn   = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.this.id}/authorizers/*"
  statement_id = "AllowExecutionFromAPIGatewayAuthorizer${substr(sha256("${aws_api_gateway_rest_api.this.id} ${each.key}"), 0, 8)}"
}

locals {
  vpc_invoke_policy = var.endpoint_type == "PRIVATE" && !var.disable_rest_api_vpc_policy ? jsonencode({
    Version = "2012-10-17",
    Statement = flatten([
      for stage in var.stages : [
        {
          Effect    = "Deny"
          Principal = "*"
          Action    = "execute-api:Invoke"
          Resource  = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.this.id}/${stage}/*/*"
          Condition = {
            StringNotEquals = {
              "aws:sourceVpc" = var.vpc_id
            }
          }
        },
        {
          Effect    = "Allow"
          Principal = "*"
          Action    = "execute-api:Invoke"
          Resource  = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.this.id}/${stage}/*/*"
        }
      ]
    ])
  }) : null
}

resource "aws_api_gateway_rest_api_policy" "vpc_invoke" {
  count       = var.endpoint_type == "PRIVATE" && !var.disable_rest_api_vpc_policy ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = local.vpc_invoke_policy

  lifecycle {
    precondition {
      condition     = var.endpoint_type != "PRIVATE" || var.vpc_id != null || var.disable_rest_api_vpc_policy
      error_message = "Missing vpc_id for endpoint_type=PRIVATE."
    }
  }
}
