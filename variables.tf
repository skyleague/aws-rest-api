variable "name" {
  description = "Name of the API Gateway"
  type        = string
}
variable "description" {
  type    = string
  default = null
}
variable "extensions" {
  description = "Top-level extensions to configure on the API Gateway. Reference: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html"
  type        = string
  default     = "{}"
}
variable "definition" {
  description = "Definition of the OpenAPI paths (see the README for examples)"
  type = map(map(object({
    # Allow additional custom integration properties
    # Reference: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions-integration.html
    x-amazon-apigateway-integration = optional(string)

    parameters = optional(string)
    responses  = optional(string)
    lambda = optional(object({
      function_name = string
    }))
    authorizer = optional(object({
      # Allow additional custom authorizer properties
      # Reference: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions-authorizer.html
      x-amazon-apigateway-authorizer = optional(string)

      lambda = optional(object({
        function_name = string
      }))
      name               = string
      authorizerType     = optional(string)
      identitySource     = optional(string)
      header             = optional(string)
      resultTtlInSeconds = optional(number)
      security           = optional(list(any))
    }))
  })))
}
variable "log_retention_in_days" {
  description = "Log retention for access logs and execution logs (set to 0 or `null` to never expire)"
  type        = number
  default     = 14
}
variable "log_kms_key_id" {
  description = "Custom KMS key for log encryption"
  type        = string
  default     = null
}
variable "log_creation_disabled" {
  description = "Disable creations of CloudWatch LogGroups"
  type        = bool
  default     = false
}
variable "log_canary_creation_disabled" {
  description = "Disable creation of CloudWatch LogGroups for Canary releases"
  type        = bool
  default     = false
}
variable "log_settings_override" {
  description = "Override log group settings for specific stages"
  type = map(object({
    disabled          = bool
    retention_in_days = number
    kms_key_id        = string
  }))
  default = {}
}
variable "stages" {
  description = "List of stages to deploy. Provide an empty array for fully custom stage management outside this module."
  type        = set(string)
  default     = ["current"]
}
variable "xray_tracing_enabled" {
  description = "Enable XRay Tracing"
  type        = bool
  default     = true
}
variable "disable_execute_api_endpoint" {
  type    = bool
  default = true
}
variable "endpoint_type" {
  description = "Valid options: REGIONAL, PRIVATE, EDGE"
  type        = string
  default     = "REGIONAL"
}
variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs to connect to (only applicable for endpoint_type=PRIVATE)"
  type        = list(string)
  default     = []
}
variable "vpc_id" {
  description = "Identifier of the VPC this API should be deployed in"
  type        = string
  default     = null
}
variable "custom_access_logs_format" {
  # Reference: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html#context-variable-reference
  description = "Logging format for Access Logs"
  type        = map(string)
  default = {
    requestId         = "$context.requestId"
    extendedRequestId = "$context.extendedRequestId"
    sourceIp          = "$context.identity.sourceIp"
    caller            = "$context.identity.caller"
    user              = "$context.identity.user"
    userArn           = "$context.identity.userArn"
    userAgent         = "$context.identity.userAgent",
    requestTime       = "$context.requestTime"
    httpMethod        = "$context.httpMethod"
    resourcePath      = "$context.resourcePath"
    path              = "$context.path"
    status            = "$context.status"
    protocol          = "$context.protocol"
    responseLength    = "$context.responseLength"
  }
}

variable "disable_global_method_settings" {
  description = "Disable global method settings. This allows custom definitions to be created outside of this module, allowing for more advance caching/throttling setups."
  type        = bool
  default     = false
}
variable "disable_rest_api_vpc_policy" {
  description = "Disable the creation of the aws_api_gateway_rest_api_policy. This allows manual creation of this policy rather than managed creation."
  type        = bool
  default     = false
}
variable "logging_level" {
  type    = string
  default = "INFO"
}
variable "metrics_enabled" {
  description = "Enable CloudWatch metrics on all endpoints"
  type        = bool
  default     = true
}
variable "data_trace_enabled" {
  description = "Log full requests to CloudWatch"
  type        = bool
  default     = false
}

variable "account_id" {
  description = "Account ID to use for the API Gateway. If not provided, the current account will be used."
  type        = string
  default     = null
}

variable "cache_cluster_enabled" {
  description = "Enable caching cluster"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Caching cluster size"
  type        = number
  default     = 0.5
}

data "aws_caller_identity" "current" {
  count = var.account_id == null ? 1 : 0
}

variable "region" {
  description = "Region to use for the API Gateway. If not provided, the current region will be used."
  type        = string
  default     = null
}
data "aws_region" "current" {
  count = var.region == null ? 1 : 0
}


locals {
  log_stages = [
    for stage in flatten([for stage in var.stages : var.log_canary_creation_disabled ? [stage] : [stage, "${stage}/Canary"]]) : stage if !(lookup(var.log_settings_override, stage, null) != null ? var.log_settings_override[stage].disabled : var.log_creation_disabled)
  ]
  region     = var.region != null ? var.region : data.aws_region.current[0].name
  account_id = var.account_id != null ? var.account_id : data.aws_caller_identity.current[0].account_id
}
