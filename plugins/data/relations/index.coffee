'use strict'

module.exports = (app) ->

  app

  .plugin 'Relations',
    version: '0.0.1'

  .initializer ->

    @include './relation-array'

    @include './belongs-to'
    @include './embeds-many'
    @include './embeds-one'
    @include './has-and-belongs-to-many'
    @include './has-many'
    @include './has-one'
    @include './references-many'

    @factory 'Relations', (Models, BelongsTo, EmbedMany, EmbedOne, HasAndBelongsToMany, HasMany, HasOne, ReferencesMany) ->

      class Relations

        @defineRelation: (type, model, params = {}) ->
          if model.model or model.as
            params = model
            model = params.model

          attach = (modelTo = {}) =>
            relation = type.define @, modelTo, params

            @relations.$define relation.as, relation

          if params.polymorphic and type not in [ 'HasOne', 'BelongsTo' ]
            attach()
          else
            Models.$get model, attach

        @hasMany: (args...) ->
          @defineRelation HasMany, args...
          @

        @belongsTo: (args...) ->
          @defineRelation BelongsTo, args...
          @

        @hasAndBelongsToMany: (args...) ->
          @defineRelation HasAndBelongsToMany, args...

        @hasOne: (args...) ->
          @defineRelation HasOne, args...
          @

        @referencesMany: (args...) ->
          @defineRelation ReferencesMany, args...
          @

        @embedMany: (args...) ->
          @defineRelation EmbedMany, args...
          @

        @embedOne: (args...) ->
          @defineRelation EmbedOne, args...
          @
