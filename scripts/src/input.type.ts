/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */
import type { ValidateFunction } from 'ajv'

export interface ApiDefinitionInput {
    [k: string]: {
        [k: string]: {
            lambda?: {
                invoke_arn: string
                function_name: string
                [k: string]: unknown
            }
            [k: string]: unknown
        }
    }
}

export const ApiDefinitionInput = {
    validate: require('./schemas/api-definition-input.schema.js') as ValidateFunction<ApiDefinitionInput>,
    get schema() {
        return ApiDefinitionInput.validate.schema
    },
    source: `${__dirname}input.schema`,
    sourceSymbol: 'apiDefinitionInput',
    is: (o: unknown): o is ApiDefinitionInput => ApiDefinitionInput.validate(o) === true,
} as const

export interface ApiDefinitionInputStringified {
    definition: string
    extensions: string
}

export const ApiDefinitionInputStringified = {
    validate: require('./schemas/api-definition-input-stringified.schema.js') as ValidateFunction<ApiDefinitionInputStringified>,
    get schema() {
        return ApiDefinitionInputStringified.validate.schema
    },
    source: `${__dirname}input.schema`,
    sourceSymbol: 'apiDefinitionInputStringified',
    is: (o: unknown): o is ApiDefinitionInputStringified => ApiDefinitionInputStringified.validate(o) === true,
} as const
