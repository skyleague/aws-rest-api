# SkyLeague `aws-rest-api` - AWS API Gateway REST API simplified

This module simplifies the deployment of AWS API Gateway REST API (v1) by consolidating all the neccessary infrastructure into this module. It leverages the capability of the REST API to deploy using the [`body`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api#body) argument, rather than deploying all the resources/methods/integrations separately. This makes for a very dynamic deployment without the hassle of maintaining the sub-resource <-> parent relations between all the path parts (for examples, see the [`aws_api_gateway_integration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) docs of Terraform).

In addition, it simplifies the integration of AWS Lambda by providing a standardized syntax to integrate AWS Lambda using the `AWS_PROXY` integration, as well as creating all the neccesary permissions for the API to invoke the Lambda functionss that are integrated with it.

## Dependencies

In order to deploy this Terraform module, you need a working `node` installation available during the deployment, with accompanying `npx` executable (usually present when `node` is installed). `node` is used in order to dynamically generate the OpenAPI `body` that defines the integrations with the REST API. The `ajv` package is a required dependency for validating the input of the generation script. This can be installed in the project `node_modules` (it likely is if you're using Javascript/Typescript in your toolchain), or as a global `npm` package.

## Usage

```terraform
module "api" {
  source = "git@github.com:skyleague/aws-rest-api.git?ref=v1.0.0"

  name   = "my-awesome-api"

  definition = jsonencode({
    "/v1/hello-world" = {
      "GET" = {
        # This also supports the aws_lambda_alias type
        lambda = aws_lambda_function.hello_world
      }
    }
  })
}
```

## Options

For a complete reference of all variables, have a look at the descriptions in [`variables.tf`](./variables.tf).

## Advanced options

Besides the `definition`, the module allows you to pass an `extensions` argument. This argument will get augmented to the top-level of the OpenAPI `body` in the creation of the REST API. The `extensions` argument allows full configuration using the [API Gateway extensions to OpenAPI](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html). As opposed to top-level extensions, the endpoint-level extensions can be configured at the same level as the `lambda` configuration. See the example below to get a glimpse of how this would work.

```hcl
module "api" {
  source = "git@github.com:skyleague/aws-rest-api.git?ref=v1.0.0"

  name   = "my-awesome-api"

  definition = jsonencode({
    "/v1/hello-world" = {
      "GET" = {
        parameters = [{
          name     = "name",
          in       = "query",
          required = true,
          type     = "string"
        }]
        "x-amazon-apigateway-integration" = {
          cacheKeyParameters = ["method.request.querystring.name"]
        }
        lambda = aws_lambda_function.hello_world
      }
    }
  })

  extensions = jsonencode({
    "x-amazon-apigateway-binary-media-types": [ "application/octet", "image/jpeg" ]
  })
}
```

## Future additions

This is the initial release of the module, with a very minimal set of standardized functionality. Most other functionality can already be achieved through [API Gateway extensions to OpenAPI](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html), even the ones mentioned for standardization below. We plan on standardizing more integrations, so feel free to leave suggestions! Candidates include:

- Authorizers (custom, apiKey, etc)
- Direct S3 integrations
- Standardized `MOCK` integrations
- Standardized `HTTP_PROXY` integrations
- ... **Your suggestions!**
