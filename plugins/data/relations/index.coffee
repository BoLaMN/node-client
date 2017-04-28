'use strict'

module.exports = (app) ->

  app

  .plugin 'Relations',
    version: '0.0.1'

  .initializer ->

    @factory 'Relations', ->
      RelationTypes =
        BelongsTo: require './belongs-to'
        EmbedMany: require './embeds-many'
        EmbedOne: require './embeds-one'
        HasAndBelongsToMany: require './has-and-belongs-to-many'
        HasMany: require './has-many'
        HasOne: require './has-one'
        ReferencesMany: require './references-many'

      class Relations

        @defineRelation: (type, model, params = {}) ->

          attach = (modelTo = {}) =>
            relation = RelationTypes[type].define @, modelTo, params

            @relations.$define relation.as, relation

          if params.polymorphic and type not in [ 'HasOne', 'BelongsTo' ]
            attach()
          else
            @models.$get model, attach

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
