module.exports = ->

  @factory 'Swagger', ->

    types = [
      'array'
      'boolean'
      'integer'
      'null'
      'number'
      'object'
      'string'
    ]

    isPrimitiveType = (typeName) ->
      types.indexOf(typeName) isnt -1

    buildFromSchemaType: (def) ->
      if typeof def is 'string' or typeof def is 'function'
        def = type: def
      else if Array.isArray def
        def = type: def

      if not def.type
        def = type: 'any'

      schema = {}

      type = def.type

      if type is 'object' and def.model
        type = def.model

      type = @getTypeName type

      if Array.isArray type
        item = type[0] or 'any'
        itemSchema = @buildFromSchemaType item

        schema.type = 'array'
        schema.items = itemSchema

        return schema

      if type is 'object' and typeof def.type is 'object'
        obj = {}

        for prop of def.type
          obj[prop] = @buildFromSchemaType def.type[prop]

        schema.type = 'object'
        schema.properties = obj

        return schema

      typeLowerCase = type.toLowerCase()

      switch typeLowerCase
        when 'date'
          schema.type = 'string'
          schema.format = 'date-time'
        when 'buffer'
          schema.type = 'string'
          schema.format = 'byte'
        when 'number'
          schema.type = 'number'
          schema.format = schema.format or 'double'
        when 'any'
          if def.source is 'path'
            schema.type = 'string'
          else
            schema.$ref = '#/definitions/x-any'
        else
          if isPrimitiveType typeLowerCase
            schema.type = typeLowerCase
          else
            schema.$ref = '#/definitions/' + type

      schema

    getTypeName: (type) ->
      if type is 'array'
        return [ 'any' ]

      if typeof type is 'string'
        arrayMatch = type.match /^\[(.*)\]$/

        if arrayMatch
          return [ arrayMatch[1] ]
        else
          return type

      if typeof type is 'function'
        return type.modelName or type.name

      if Array.isArray type
        return type

      if typeof type is 'object'
        return 'object'

      'any'
