import type { ApiDefinitionInput } from './input.type'
import { stableHash } from './util'

function formatMethod(method: string): string {
    method = method.toLowerCase()
    if (method === 'any') {
        return 'x-amazon-apigateway-any-method'
    }
    return method
}

function formatLambdaIntegration(lambda: ApiDefinitionInput[string][string]['lambda'], config: Record<string, unknown>) {
    const integration = config['x-amazon-apigateway-integration'] as Record<string, unknown> | undefined
    if (lambda !== undefined && lambda !== null) {
        return {
            ...integration,
            httpMethod: 'POST',
            type: 'aws_proxy',
            uri: lambda.invoke_arn,
        }
    }
    return integration
}

function collectPathParameters(p: string, config: Record<string, unknown>) {
    const parameters: unknown[] = (config.parameters as unknown[]) ?? []
    for (const part of p.split('/')) {
        const { param } = /^\{(?<param>.*\+?)\}$/.exec(part)?.groups ?? {}
        if (param !== undefined && !parameters.some((x) => (x as { name?: string }).name === param)) {
            parameters.push({
                in: 'path',
                required: true,
                schema: { type: 'string' },
                name: param,
            })
        }
    }

    if (parameters.length === 0) {
        return undefined
    }
    return parameters
}

export function createOpenApiSpec({ input, extensions }: { input: ApiDefinitionInput; extensions: string | undefined }) {
    const ext = JSON.parse(extensions ?? '{}') as Record<string, unknown>
    const authorizers = Object.values(input).flatMap((configs) =>
        Object.values(configs)
            .map(({ authorizer }) => {
                if (authorizer === undefined) {
                    return undefined
                }
                const {
                    name,
                    lambda,
                    header = 'Authorization',
                    authorizerType = 'request',
                    identitySource,
                    cacheTtl = 0,
                    ...config
                } = authorizer
                return [
                    name,
                    {
                        type: 'apiKey',
                        'x-amazon-apigateway-authtype': 'custom',
                        ...config,
                        in: 'header',
                        name: header,
                        'x-amazon-apigateway-authorizer': {
                            type: authorizerType,
                            identitySource: identitySource ?? `method.request.header.${header}`,
                            authorizerUri: lambda?.invoke_arn,
                            authorizerResultTtlInSeconds: cacheTtl,
                            ...(config['x-amazon-apigateway-authorizer'] as Record<string, unknown>),
                        },
                    },
                ] as const
            })
            .filter(<T>(x: T | undefined): x is T => x !== undefined)
    )
    const authorizerNames = [...new Set(authorizers.map(([name]) => name))]
    for (const name of authorizerNames) {
        const matches = authorizers.filter(([n]) => n === name).map(([, a]) => a)
        if (matches.length > 1 && [...new Set(matches.map(stableHash))].length !== 1) {
            throw new Error(`Encountered mismatching definitions for authorizer: ${name}`)
        }
    }
    const components = {
        ...(ext?.components as Record<string, unknown>),
        securitySchemes: {
            ...((ext?.components as Record<string, unknown>)?.securitySchemes as Record<string, unknown>),
            ...Object.fromEntries(authorizers),
        },
    }
    return {
        openapi: '3.0.1',
        ...ext,
        paths: Object.fromEntries(
            Object.entries(input).map(([p, configs]) => [
                p,
                Object.fromEntries(
                    Object.entries(configs).map(([method, { lambda, authorizer, ...config }]) => [
                        formatMethod(method),
                        {
                            ...config,
                            parameters: collectPathParameters(p, config),
                            'x-amazon-apigateway-integration': formatLambdaIntegration(lambda, config),
                            security:
                                authorizer !== undefined
                                    ? [{ [authorizer.name]: [] }, ...((config.security as unknown[] | undefined) ?? [])]
                                    : config.security,
                        },
                    ])
                ),
            ])
        ),
        components:
            Object.keys(components).length > 1 || Object.keys(components.securitySchemes).length > 0 ? components : undefined,
    }
}
