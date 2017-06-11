
module.exports = ->

  @validator 'String', (Validator) ->

    class String extends Validator
 
      @minLength: (a, e) ->
        a >= e

      @maxLength: (a, e) ->
        a <= e

      @pattern: (a, e) ->
        e = if typeof e is 'string' then (e = new RegExp(e)) else e

        e.test a