import { createOpenApiSpec } from './create-openapi'

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
        Object {
          "components": Object {
            "securitySchemes": Object {
              "barAuthorizer": Object {
                "in": "header",
                "name": "Authorization",
                "type": "apiKey",
                "x-amazon-apigateway-authorizer": Object {
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
          "paths": Object {
            "/v1/foo": Object {
              "get": Object {
                "parameters": undefined,
                "security": Array [
                  Object {
                    "barAuthorizer": Array [],
                  },
                ],
                "x-amazon-apigateway-integration": Object {
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
