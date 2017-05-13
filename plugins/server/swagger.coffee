module.exports = ->

  @factory 'Swagger', (Types, TypeOf, Models) ->

    buildFromSchemaType: (def) ->
      if typeof def is 'string' or typeof def is 'function'
        def = type: def
      else if Array.isArray def
        def = type: def

      type = def.type or def

      if type is 'object' and def.model
        type = def.model

      if typeof type is 'string'
        kind = type
      else
        kind = TypeOf type

      switch kind
        when 'array'
          item = type[0] or 'any'

          type: 'array'
          items: @buildFromSchemaType item
        when 'object'
          obj = {}

          for prop, val of type
            obj[prop] = @buildFromSchemaType val

          type: 'object'
          properties: obj
        when 'string'
          fn = Types.get type.toLowerCase()
          fn ?= Models.get type

          if not fn?.swagger?.schema
            console.log 'no swagger definition found for ', type
            return

          schema = fn.swagger.schema def

          if def.source is 'body'
            schema: schema
          else schema
