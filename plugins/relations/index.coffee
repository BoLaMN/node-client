'use strict'

module.exports = (app) ->

  app

  .module 'Relations', []

  .initializer ->

    @include './relation'
    @include './relation-array'

    @assembler 'relation', ->
      (name, factory) ->
        @factory name, factory, 'relation'

    @include './belongs-to'
    @include './has-many'
    @include './has-one'
    @include './embeds-many'
    @include './embeds-one'
    @include './has-and-belongs-to-many'
    @include './references-many'

    @factory 'Relations', (Models, inflector, injector) ->
      { camelize } = inflector

      class Relations

        @relation: (name, config, type) ->
          args = arguments
          type = camelize config.type or type

          { polymorphic, model } = config
        
          config.as = name 

          attach = (modelTo = {}) =>
            delete config.model
            ctor = injector.get type
            
            relation = ctor.define @, modelTo, config
            relation.property '$args', value: args

          if not model and polymorphic and type not in [ 'HasOne', 'BelongsTo' ]
            attach()
          else
            Models.get model, attach

          @

        @hasMany: (args...) ->
          @relation args..., 'hasMany'

        @belongsTo: (args...) ->
          @relation args..., 'belongsTo'

        @hasAndBelongsToMany: (args...) ->
          @relation args..., 'hasAndBelongsToMany'

        @hasOne: (args...) ->
          @relation args..., 'hasOne'

        @referencesMany: (args...) ->
          @relation args..., 'referencesMany'

        @embedMany: (args...) ->
          @relation args..., 'embedMany',

        @embedOne: (args...) ->
          @relation args..., 'embedOne'
