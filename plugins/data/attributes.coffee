module.exports = ->

  @factory 'Attributes', (Storage, Validators, Utils, debug) ->
    { wrap } = Utils

    class Attributes extends Storage

      validate: (object, next) ->

        validate = (attr, cb) =>

          Validators.get @[attr].type, (validator) =>
            validators = []

            for own key, options of @[attr] 
              if typeof validator[key] is 'function'
                validators.push 
                  key: key
                  opts: options

            @$each validators, ({ key, opts }, next) =>

              done = (err, results) ->
                debug 'validation ' + key + ' valid: ' + results

                next err

              wrap(validator[key], done).apply @, [ object[attr], opts, object ]
            , cb
            
        @$each @keys, validate, next

        return
