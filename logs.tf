resource "aws_cloudwatch_log_group" "execution" {
  for_each = {
    for stage, config in {
      for stage in local.log_stages : stage => lookup(var.log_settings_override, stage, {
        disabled          = var.log_creation_disabled
        retention_in_days = var.log_retention_in_days
        kms_key_id        = var.log_kms_key_id
      })
    } : stage => config if !config.disabled
  }
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.this.id}/${each.key}"
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
}

resource "aws_cloudwatch_log_group" "access" {
  for_each = {
    for stage, config in {
      for stage in local.log_stages : stage => lookup(var.log_settings_override, stage, {
        disabled          = var.log_creation_disabled
        retention_in_days = var.log_retention_in_days
        kms_key_id        = var.log_kms_key_id
      })
    } : stage => config if !config.disabled
  }
  name              = "API-Gateway-Access-Logs_${aws_api_gateway_rest_api.this.id}/${each.key}"
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
}
