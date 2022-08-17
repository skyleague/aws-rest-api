import { createOpenApiSpec } from './create-openapi'

test('simple', () => {
    expect(
        createOpenApiSpec({
            input: {
                '/v1/foo': {
                    get: {
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
          "openapi": "3.0.1",
          "paths": Object {
            "/v1/foo": Object {
              "get": Object {
                "parameters": undefined,
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
