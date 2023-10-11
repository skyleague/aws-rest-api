locals {
  invoke_arns = {
    for function_name in toset(flatten([
      for http_path, path_items in var.definition : flatten([
        for http_method, path_item in path_items : concat(
          try([path_item.lambda.function_name], []),
          try([path_item.authorizer.lambda.function_name], []),
        )
      ])
    ])) : function_name => "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${local.region}:${local.account_id}:function:${function_name}/invocations"
  }
  authorizers = flatten([
    for http_path, path_items in var.definition : flatten([
      for http_method, path_item in path_items : zipmap(
        [path_item.authorizer.name],
        [{
          type = "apiKey"
          "x-amazon-apigateway-authtype" : "custom"
          in   = "header"
          name = coalesce(try(path_item.authorizer.header, null), "Authorization")
          "x-amazon-apigateway-authorizer" = merge(
            {
              type                         = coalesce(try(path_item.authorizer.authorizerType, null), "request")
              identitySource               = coalesce(try(path_item.authorizer.identitySource, null), "method.request.header.${coalesce(try(path_item.authorizer.header, null), "Authorization")}")
              authorizerResultTtlInSeconds = coalesce(try(path_item.authorizer.resultTtlInSeconds, null), 0)
            },
            try({ authorizerUri = local.invoke_arns[path_item.authorizer.lambda.function_name] }, {}),
            try(jsondecode(path_item.authorizer["x-amazon-apigateway-authorizer"]), {})
          )
        }],
      ) if try(path_item.authorizer, null) != null
    ])
  ])
  parsed_extensions = jsondecode(var.extensions)
  components = merge(try(local.parsed_extensions.components, {}), {
    securitySchemes = merge(
      try(local.parsed_extensions.components.securitySchemes, {}),
      reverse(local.authorizers)...
    )
  })
  parameters = {
    for http_path, path_items in var.definition : http_path => {
      for http_method, path_item in path_items : http_method => concat(
        coalesce(try(jsondecode(path_item.parameters), null), []),
        [
          for parameter in regexall("\\{([a-zA-Z0-9:._$-]+\\+?)\\}", http_path) : {
            in       = "path"
            required = true
            schema   = { type = "string" }
            name     = parameter[0]
          } if length([for param in coalesce(try(jsondecode(path_item.parameters), null), []) : param if param.name == parameter[0]]) == 0
        ]
      )
    }
  }
  security = {
    for http_path, path_items in var.definition : http_path => {
      for http_method, path_item in path_items : http_method => concat(
        try(path_item.authorizer, null) != null ? [merge([
          for authorizer in local.authorizers : {
            for name, value in authorizer : name => [] if path_item.authorizer.name == name
          }
        ]...)] : [],
        try(path_item.security, []),
      )
    }
  }
  compiled_definition = merge(local.parsed_extensions, {
    openapi = try(local.parsed_extensions.openapi, "3.0.1")
    paths = {
      for http_path, path_items in var.definition : http_path => {
        for http_method, path_item in path_items : http_method == "any" ? "x-amazon-apigateway-any-method" : lower(http_method) => { for k, v in {
          "x-amazon-apigateway-integration" = merge(try(jsondecode(path_item["x-amazon-apigateway-integration"]), {}), try(path_item.lambda, null) != null ? {
            httpMethod = "POST"
            type       = "aws_proxy"
            uri        = local.invoke_arns[path_item.lambda.function_name]
          } : {})
          parameters = length(try(local.parameters[http_path][http_method], [])) > 0 ? local.parameters[http_path][http_method] : null
          responses  = try(jsondecode(path_item.responses), null)
          security   = length(try(local.security[http_path][http_method], [])) > 0 ? local.security[http_path][http_method] : null
        } : k => v if v != null }
      }
    }
    components = local.components
  })
}

