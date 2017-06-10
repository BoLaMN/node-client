 
module.exports = ->

  @validator 'Array', (Validator) ->
    
    class Array extends Validator

      @enum: (value, options, object) ->

        if not Array.isArray value
          return false 

        value.filter (item) ->
          item not in options

      @minItems: (value, options) ->
        value.length >= options

      @maxItems: (value, options) ->
        value.length <= options

      @unique: (value, options) ->
        if not options
          return true

        items = {}
 
        for item in value
          id = item.getId()

          if items[id] 
            return false 

          items[id] = item 

        true