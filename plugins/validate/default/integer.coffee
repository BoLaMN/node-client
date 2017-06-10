
module.exports = ->

  @validator 'Integer', (Validator) ->

    class Integer extends Validator
      
      @minimum: (a, e) ->
        a >= e

      @maximum: (a, e) ->
        a <= e

      @exclusiveMinimum: (a, e) ->
        a > e

      @exclusiveMaximum: (a, e) ->
        a < e

      @divisibleBy: (a, e) ->
        multiplier = Math.max((a - Math.floor(a)).toString().length - 2, (e - Math.floor(e)).toString().length - 2)
        multiplier = if multiplier > 0 then 10 ** multiplier else 1

        a * multiplier % e * multiplier == 0

  @validator 'Float', (Validators) ->

    class Float extends Validators.integer

  @validator 'Number', (Validators) ->

    class Number extends Validators.integer
