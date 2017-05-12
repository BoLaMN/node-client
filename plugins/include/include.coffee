'use strict'

module.exports = ->

  @factory 'Inclusion', (injector, Utils, isString, isPlainObject) ->
    { mergeQuery, clone } = Utils

    normalizeInclude = (include) ->
      if isString include
        [ include ]
      else if isPlainObject include
        rel = include.rel or include.relation

        if isString rel
          obj = {}
          obj[rel] = new IncludeScope include.scope

          [ obj ]
        else
          newInclude = []

          Object.keys(include).forEach (key) ->
            obj = {}
            obj[key] = include[key]

            newInclude.push obj

          newInclude
      else if Array.isArray include
        include.map normalizeInclude
      else
        false

    processIncludeItem = (relations, objs, options) ->
      (include) ->
        subInclude = null
        scope = {}

        if isPlainObject include
          relationName = Object.keys(include)[0]

          if include[relationName] instanceof IncludeScope
            scope = include[relationName]
            subInclude = scope.include()
          else
            subInclude = include[relationName]
        else
          relationName = include

        relation = relations[relationName]

        if relation.options.disableInclude
          return Promise.resolve()

        if not relation
          return Promise.reject new Error "Relation #{ relationName } is not defined"

        if not relation.to and not relation.polymorphic
          return Promise.reject new Error "relation.to is not defined for relation #{ relationName } and is no polymorphic"

        filter = scope.conditions() or where: {}

        if (relation.multiple or relation.type == 'belongsTo') and scope

          if filter.fields and Array.isArray(subInclude) and relation.to.relations
            includeScope = fields: []

            subInclude.forEach (name) ->
              rel = relation.to.relations[name]

              if rel and rel.type == 'belongsTo'
                includeScope.fields.push rel.primaryKey

          mergeQuery filter, includeScope, fields: false

        fields = filter.fields

        if Array.isArray(fields) and fields.indexOf(relation.foreignKey) is -1
          fields.push relation.foreignKey
        else if isPlainObject(fields) and !fields[relation.foreignKey]
          fields[relation.foreignKey] = true

        if relation.polymorphic
          cls = injector.get relation.$type + 'PolymorphicInclude'
        else if relation.through
          cls = injector.get 'HasManyThroughInclude'
        else
          cls = injector.get relation.$type + 'Include'

        new cls relation, options, subInclude, objs
          .handle()

    class IncludeScope
      constructor: (scope = {}) ->
        @_scope = clone scope
        @_include = null

        if @_scope.include
          @_include = normalizeInclude @_scope.include
          delete @_scope.include

        return

      include: ->
        @_include

      conditions: ->
        clone @_scope

    class Inclusion

      @include: (objects, include, options = {}) ->
        include = normalizeInclude include

        if not include
          return Promise.resolve objects

        Promise.each include, processIncludeItem @relations, objects, options
