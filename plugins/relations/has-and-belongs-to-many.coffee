module.exports = ->

  @factory 'HasAndBelongsToMany', (HasMany, Models, Model) ->

    class HasAndBelongsToMany extends HasMany

      @initialize: (from, @model, params) ->
        super

        if not @through
          if @polymorphic
            throw new Error "{{Polymorphic}} relations need a through model"

          if @throughModel
            @through = @throughModel
          else
            name1 = from.name + @model.name
            name2 = @model.name + from.name

            @through = Models.get(name1) or Models.get(name2)

            if not @through
              @through = Model.define name1

        if @through
          @through.belongsTo @model.name

        @

      constructor: ->
        return super
