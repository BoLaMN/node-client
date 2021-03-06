module.exports = ->

  @value 'Routes', ->
    ->
      primaryKeyType = @attributes[@primaryKey]?.type or 'string'

      destroy:
        params:
          where:
            description: "filter.where object"
            type: "object"
            source: 'query'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          count:
            type: 'object'
            description: 'The number of instances deleted'
            root: true
        accessType: "WRITE"
        description: "Delete all matching records."
        path: "/"
        method: "delete"

      destroyById:
        params:
          "#{ @primaryKey }":
            description: "Model #{ @primaryKey }"
            source: "path"
            type: primaryKeyType
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          count:
            type: 'object'
            description: 'The number of instances deleted'
            root: true
        accessType: "WRITE"
        aliases: [
          "destroyById"
          "removeById"
        ]
        description: "Delete a model instance by #{ @primaryKey } from the data source."
        path: "/:#{ @primaryKey }"
        method: "del"

      create:
        params:
          data:
            description: "Model instance data"
            source: "body"
            type: "object"
            root: true
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        returns: 
          data:
            type: 'any'
            root: true 
        accessType: "WRITE"
        description: "Create a new instance of the model and persist it into the data source."
        path: "/"
        method: "post"

      count:
        params:
          where:
            description: "Criteria to match model instances"
            type: "object"
            required: false
            source: 'query'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns: 
          count:
            type: 'number'
        accessType: "READ"
        description: "Count instances of the model matched by where from the data source."
        path: "/count"
        method: "get"

      exists:
        params:
          "#{ @primaryKey }":
            description: "Model #{ @primaryKey }"
            type: primaryKeyType
            source: 'path'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns: 
          exists:
            type: 'boolean'
        accessType: "READ"
        description: "Check whether a model instance exists in the data source."
        path: "/:#{ @primaryKey }"
        method: "head"

      find:
        params:
          filter:
            description: "Filter defining fields, where, include, order, offset, and limit"
            type: "object"
            source: 'query'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: [ @name ]
            root: true 
        accessType: "READ"
        description: "Find all instances of the model matched by filter from the data source."
        path: "/"
        method: "get"

      findById:
        params:
          "#{ @primaryKey }":
            description: "Model #{ @primaryKey }"
            source: "path"
            type: primaryKeyType
          filter:
            description: "Filter defining fields and include"
            type: "object"
            source: 'query'
            required: false
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: @name
            root: true 
        accessType: "READ"
        description: "Find a model instance by #{ @primaryKey } from the data source."
        path: "/:#{ @primaryKey }"
        method: "get"

      findOne:
        params:
          filter:
            description: "Filter defining fields, where, include, order, offset, and limit"
            type: "object"
            source: 'query'
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: @name
            root: true 
            default: {}
        accessType: "READ"
        description: "Find first instance of the model matched by filter from the data source."
        path: "/findOne"
        method: "get"

      'prototype.updateAttributes':
        params:
          "#{ @primaryKey }":
            description: "Model #{ @primaryKey }"
            source: "path"
            type: primaryKeyType
          data:
            description: "An object of model property name/value pairs"
            source: "body"
            root: true
            type: "object"
          options:
            type: 'object'
            source: 'context'
            required: false
        returns:
          data: 
            type: @name
            root: true 
        accessType: "WRITE"
        aliases: [
          "patchAttributes"
        ]
        description: "Patch attributes for a model instance and persist it into the data source."
        path: "/:#{ @primaryKey }"
        method: "patch"

      update:
        params:
          where:
            description: "Criteria to match model instances"
            source: "query"
            type: "object"
          data:
            description: "An object of model property name/value pairs"
            source: "body"
            type: "object"
            root: true
          options:
            type: 'object'
            source: 'context'
            required: false
        returns: 
          count:
            description: 'The number of instances updated'
            type: 'number'
            root: true
        accessType: "WRITE"
        aliases: [
          "update"
        ]
        description: "Update instances of the model matched by where from the data source."
        path: "/"
        method: "put"

      updateById:
        params:
          "#{ @primaryKey }":
            description: "Model #{ @primaryKey }"
            source: "path"
            type: primaryKeyType
          data:
            description: "Model instance data"
            source: "body"
            type: "object"
            root: true
          options:
            type: 'object'
            source: 'context'
            required: false
        returns: 
          success:
            type: 'boolean'
        accessType: "WRITE"
        description: "Replace attributes for a model instance and persist it into the data source."
        path: "/:#{ @primaryKey }"
        method: "put"

      #patchOrCreate:
      #  params:
      #    data:
      #      description: "Model instance data"
      #      source: "body"
      #      type: "object"
      #  returns:
      #    data: 
      #      type: @name
      #      root: true 
      #  accessType: "WRITE"
      #  aliases: [
      #    "upsert"
      #    "updateOrCreate"
      #  ]
      #  description: "Patch an existing model instance or insert a new one into the data source."
      #  path: "/"
      #  method: "patch"

      #replaceOrCreate:
      #  params:
      #    data:
      #      description: "Model instance data"
      #      source: "body"
      #      type: "object"
      #  returns:
      #    data: 
      #      type: @name
      #      root: true 
      #  accessType: "WRITE"
      #  description: "Replace an existing model instance or insert a new one into the data source."
      #  path: "/replaceOrCreate"
      #  method: "post"

      #findOrCreate:
      #  description: 'Find else create a new instance of the model and persist it into the data source'
      #  params:
      #    data:
      #      type: 'object'
      #      source: 'body'
      #  returns:
      #    data: 
      #      type: @name
      #      root: true 
      #  method: 'post'
      #  path: '/findOrCreate'
