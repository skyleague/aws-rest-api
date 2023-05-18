resource "aws_api_gateway_rest_api" "this" {
  name        = var.name
  description = coalesce(var.description, "API for ${var.name}")

  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  endpoint_configuration {
    types            = [var.endpoint_type]
    vpc_endpoint_ids = var.endpoint_type == "PRIVATE" ? var.vpc_endpoint_ids : null
  }

  body = jsonencode(local.compiled_definition)

  lifecycle {
    precondition {
      condition     = var.endpoint_type != "PRIVATE" || length(var.vpc_endpoint_ids) > 0
      error_message = "At least one vpc_endpoint_id needs to be provided when endpoint_type=PRIVATE."
    }
  }
}

resource "aws_api_gateway_method_settings" "this" {
  for_each = var.disable_global_method_settings ? [] : var.stages

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this[each.key].stage_name
  method_path = "*/*"

  settings {
    logging_level      = var.logging_level
    metrics_enabled    = var.metrics_enabled
    data_trace_enabled = var.data_trace_enabled
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(aws_api_gateway_rest_api.this.body)
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api_policy.vpc_invoke,
  ]
}

resource "aws_api_gateway_stage" "this" {
  for_each      = var.stages
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = each.value

  xray_tracing_enabled = var.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = var.custom_access_logs_format != null ? [var.custom_access_logs_format] : []
    content {
      destination_arn = aws_cloudwatch_log_group.access[each.key].arn
      format          = jsonencode(access_log_settings.value)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.execution,
    aws_lambda_permission.api_invoke,
    aws_lambda_permission.authorizer_invoke,
  ]
}
