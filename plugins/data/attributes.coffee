module.exports = ->

  @factory 'Attributes', (Storage, Validators, debug) ->

    class Attributes extends Storage

      validate: (object, next) ->

        validate = (attr, cb) =>

          Validators.get @[attr].type, (validator) =>

            for own key, options of @[attr] 
              if typeof validator[key] is 'function'
                fn = validator[key].bind @
                valid = fn object[attr], options, object
                
                debug 'validation ' + key, options, valid  

                valid 

            cb()
            
        @$each @keys, validate, next

        return
