# SkyLeague `aws-rest-api` - AWS API Gateway REST API simplified

[![tfsec](https://github.com/skyleague/aws-rest-api/actions/workflows/tfsec.yml/badge.svg?branch=main)](https://github.com/skyleague/aws-rest-api/actions/workflows/tfsec.yml)

This module simplifies the deployment of AWS API Gateway REST API (v1) by consolidating all the neccessary infrastructure into this module. It leverages the capability of the REST API to deploy using the [`body`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api#body) argument, rather than deploying all the resources/methods/integrations separately. This makes for a very dynamic deployment without the hassle of maintaining the sub-resource <-> parent relations between all the path parts (for examples, see the [`aws_api_gateway_integration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) docs of Terraform).

In addition, it simplifies the integration of AWS Lambda by providing a standardized syntax to integrate AWS Lambda using the `AWS_PROXY` integration, as well as creating all the neccesary permissions for the API to invoke the Lambda functionss that are integrated with it.

## Usage

```terraform
module "api" {
  source = "git@github.com:skyleague/aws-rest-api.git?ref=v1.0.0"

  name   = "my-awesome-api"

  definition = jsonencode({
    "/v1/hello-world" = {
      "GET" = {
        lambda = {
          function_name = "prefix-hello-world"
        }
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
        lambda = {
          function_name = "prefix-hello-world"
        }
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

This open source library package is part of the SkyLeague modern application delivery stack.

## Support

SkyLeague provides Enterprise Support on this open-source library package at clients across industries. Please get in touch via [`https://skyleague.io`](https://skyleague.io).

If you are not under Enterprise Support, feel free to raise an issue and we'll take a look at it on a best-effort basis!

## License & Copyright

This library is licensed under the MIT License (see [LICENSE.md](./LICENSE.md) for details).

If you using this SDK without Enterprise Support, please note this (partial) MIT license clause:

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

Copyright (c) 2022, SkyLeague Technologies B.V..
'SkyLeague' and the astronaut logo are trademarks of SkyLeague Technologies, registered at Chamber of Commerce in The Netherlands under number 86650564.

All product names, logos, brands, trademarks and registered trademarks are property of their respective owners. All company, product and service names used in this website are for identification purposes only. Use of these names, trademarks and brands does not imply endorsement.
