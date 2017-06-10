
module.exports = ->

  @factory 'ValidatorMessages', ->
    
    required: 'is required'
    minLength: 'is too short (minimum is %{expected} characters)'
    maxLength: 'is too long (maximum is %{expected} characters)'
    pattern: 'invalid input'
    minimum: 'must be greater than or equal to %{expected}'
    maximum: 'must be less than or equal to %{expected}'
    exclusiveMinimum: 'must be greater than %{expected}'
    exclusiveMaximum: 'must be less than %{expected}'
    divisibleBy: 'must be divisible by %{expected}'
    minItems: 'must contain more than %{expected} items'
    maxItems: 'must contain less than %{expected} items'
    uniqueItems: 'must hold a unique set of values'
    format: 'is not a valid %{expected}'
    conform: 'must conform to given constraint'
    type: 'must be of %{expected} type'
    additionalProperties: 'must not exist'
    unknown: 'is not defined in schema'
    enum: 'must be present in given enumerator'
