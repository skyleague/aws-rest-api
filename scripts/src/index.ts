import { createOpenApiSpec } from './create-openapi'
import { ApiDefinitionInput, ApiDefinitionInputStringified } from './input.type'

async function readInput<T>(schema: {
    is: (o: unknown) => o is T
    validate: { errors?: { message?: string }[] | null }
}): Promise<T> {
    const chunks: Buffer[] = []
    for await (const chunk of process.stdin) {
        chunks.push(Buffer.from(chunk as Buffer))
    }
    const input: unknown = JSON.parse(Buffer.concat(chunks).toString('utf-8'))
    if (schema.is(input)) {
        return input
    } else {
        throw new Error(schema.validate.errors?.[0].message ?? 'Invalid input')
    }
}
async function main() {
    const { definition, extensions } = await readInput(ApiDefinitionInputStringified)
    const input: unknown = JSON.parse(definition)
    if (!ApiDefinitionInput.is(input)) {
        throw new Error(ApiDefinitionInput.validate.errors?.[0].message ?? 'Invalid input')
    }

    const spec = createOpenApiSpec({ input, extensions })
    console.log(JSON.stringify({ spec: JSON.stringify(spec) }))
}

void main()
