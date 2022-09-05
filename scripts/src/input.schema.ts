import { $number, $object, $optional, $string, $unknown, $validator } from '@skyleague/therefore'

const lambdaResource = $object(
    {
        invoke_arn: $string,
        function_name: $string,
    },
    { indexSignature: $unknown }
)
export const apiDefinitionInput = $validator(
    $object(
        {},
        {
            indexSignature: $object(
                {},
                {
                    indexSignature: $object(
                        {
                            lambda: $optional(lambdaResource),
                            authorizer: $optional(
                                $object(
                                    {
                                        lambda: $optional(lambdaResource),
                                        name: $string(),
                                        authorizerType: $optional($string),
                                        identitySource: $optional($string),
                                        header: $optional($string),
                                        cacheTtl: $optional($number),
                                    },
                                    { indexSignature: $unknown }
                                )
                            ),
                        },
                        { indexSignature: $unknown }
                    ),
                }
            ),
        }
    ),
    { assert: false }
)

export const apiDefinitionInputStringified = $validator(
    $object({
        definition: $string,
        extensions: $string,
    }),
    { assert: false }
)
