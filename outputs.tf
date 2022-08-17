output "rest_api" {
  value = aws_api_gateway_rest_api.this
}

output "stage" {
  value = aws_api_gateway_stage.this
}

output "access_log_groups" {
  value = aws_cloudwatch_log_group.access
}

output "execution_log_groups" {
  value = aws_cloudwatch_log_group.execution
}
