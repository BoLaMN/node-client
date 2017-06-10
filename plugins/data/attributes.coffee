module.exports = ->

  @factory 'Attributes', (Storage, Validators) ->

    class Attributes extends Storage
      @debug: true 
      
      validate: (object) ->

        validate = (attr, cb) =>

          Validators.get @[attr].type, (validator) =>

            for own key, options of @[attr] when validator[key]?()
              assert = validator[key].bind @

              assert object[attr], options, object
              
            cb()
            
        @$each @keys, validate, next
