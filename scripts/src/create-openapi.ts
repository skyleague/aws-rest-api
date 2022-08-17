import type { ApiDefinitionInput } from './input.type'

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
    return {
        openapi: '3.0.1',
        ...(JSON.parse(extensions ?? '{}') as Record<string, unknown>),
        paths: Object.fromEntries(
            Object.entries(input).map(([p, configs]) => [
                p,
                Object.fromEntries(
                    Object.entries(configs).map(([method, { lambda, ...config }]) => [
                        formatMethod(method),
                        {
                            ...config,
                            parameters: collectPathParameters(p, config),
                            'x-amazon-apigateway-integration': formatLambdaIntegration(lambda, config),
                        },
                    ])
                ),
            ])
        ),
    }
}
