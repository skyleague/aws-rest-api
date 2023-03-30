import { createOpenApiSpec } from './create-openapi.js'

test('simple', () => {
    expect(
        createOpenApiSpec({
            input: {
                '/v1/foo': {
                    get: {
                        authorizer: {
                            name: 'barAuthorizer',
                            lambda: {
                                function_name: 'bar',
                                invoke_arn: 'arn:bar',
                            },
                        },

                        lambda: {
                            function_name: 'foo',
                            invoke_arn: 'arn:foo',
                        },
                    },
                },
            },

            extensions: undefined,
        })
    ).toMatchInlineSnapshot(`
        {
          "components": {
            "securitySchemes": {
              "barAuthorizer": {
                "in": "header",
                "name": "Authorization",
                "type": "apiKey",
                "x-amazon-apigateway-authorizer": {
                  "authorizerResultTtlInSeconds": 0,
                  "authorizerUri": "arn:bar",
                  "identitySource": "method.request.header.Authorization",
                  "type": "request",
                },
                "x-amazon-apigateway-authtype": "custom",
              },
            },
          },
          "openapi": "3.0.1",
          "paths": {
            "/v1/foo": {
              "get": {
                "parameters": undefined,
                "security": [
                  {
                    "barAuthorizer": [],
                  },
                ],
                "x-amazon-apigateway-integration": {
                  "httpMethod": "POST",
                  "type": "aws_proxy",
                  "uri": "arn:foo",
                },
              },
            },
          },
        }
    `)
})
