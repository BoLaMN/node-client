'use strict'

module.exports = (app) ->

  app

  .module 'Relations', []

  .initializer ->

    @include './relation'
    @include './relation-array'

    @include './belongs-to'
    @include './has-many'
    @include './has-one'
    @include './embeds-many'
    @include './embeds-one'
    @include './has-and-belongs-to-many'
    @include './references-many'

    @factory 'Relations', (Models, injector) ->

      class Relations

        @defineRelation: (type, model, params = {}) ->
          args = arguments

          if model.model or model.as
            params = model
            model = params.model

          attach = (modelTo = {}) =>
            relation = injector.get(type).define @, modelTo, params
            relation.property '$args', value: args

            @relations.$define relation.as, relation

            if @__super__.constructor.name is 'SharedModel'
              routes = injector.get(type + 'Routes') or
                       injector.get 'RelationRoutes'

              for name, config of routes.bind(relation)()
                @remoteMethod name, config

          if params.polymorphic and type not in [ 'HasOne', 'BelongsTo' ]
            attach()
          else
            Models.$get model, attach

        @hasMany: (args...) ->
          @defineRelation 'HasMany', args...
          @

        @belongsTo: (args...) ->
          @defineRelation 'BelongsTo', args...
          @

        @hasAndBelongsToMany: (args...) ->
          @defineRelation 'HasAndBelongsToMany', args...

        @hasOne: (args...) ->
          @defineRelation 'HasOne', args...
          @

        @referencesMany: (args...) ->
          @defineRelation 'ReferencesMany', args...
          @

        @embedMany: (args...) ->
          @defineRelation 'EmbedMany', args...
          @

        @embedOne: (args...) ->
          @defineRelation 'EmbedOne', args...
          @
