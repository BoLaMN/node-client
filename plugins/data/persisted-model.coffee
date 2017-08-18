module.exports = ->

  @factory 'PersistedModel', (Model, Context, utils, ObjectProxy, assert, Models) ->
    { getArgs } = utils

    class PersistedModel extends Model

      @create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        @execute 'create', data, options
          .asCallback cb

      @count: (filter = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @count filter, {}, options

        if not filter.where
          filter = where: filter

        @execute 'count', filter, options
          .asCallback cb

      @destroy: (filter = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy filter, {}, options

        if not filter.where
          filter = where: filter

        @execute 'destroy', filter, options
          .asCallback cb

      @destroyById: (id, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroyById id, {}, options

        assert id, 'The id argument is required'

        @execute 'destroyById', id, options
          .asCallback cb

      @exists: (id, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @exists id, {}, options

        assert id, 'The id argument is required'

        filter = where:
          id: id

        @execute 'count', filter, options
          .then (data) -> not not data
          .asCallback cb

      @execute: (command, args...) ->
        new Context @, command, args...

      @find: (filter = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @find filter, {}, options

        if typeof filter is 'function'
          return @find {}, {}, filter

        @execute 'find', filter, options
          .asCallback cb

      @findOne: (filter = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findOne filter, {}, options

        if not filter.where
          filter = where: filter

        @execute 'findOne', filter, options
          .asCallback cb

      @findById: (id, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findById id, {}, options

        assert id, 'The id argument is required'

        filter = where:
          id: id

        @execute 'findOne', filter, options
          .asCallback cb

      @findByIds: (ids = [], options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findByIds ids, {}, options

        assert ids.length, 'The ids argument is requires ids'

        filter = where:
          id: inq: ids

        @find filter, options
          .asCallback cb

      @update: (filter = {}, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateAll filter, data, {}, options

        @execute 'update', filter, data, options
          .asCallback cb

      @updateById: (id, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateById id, data, {}, options

        assert id, 'The id argument is required'

        filter = where:
          id: id

        @update filter, data, options
          .asCallback cb

      constructor: (data = {}, options = {}) ->
        return super

      execute: (command, args...) ->
        model = Models.get @constructor.name
        fn = model[command]

        newArgs = []
        argNames = getArgs fn

        options = argNames.indexOf 'options'

        if options > -1
          newArgs[options - 1] = args[options - 1] or {}
          newArgs[options - 1].instance = @

        data = argNames.indexOf 'data'

        if data > -1
          newArgs[data - 1] = @

        if argNames[0] is 'id'
          newArgs.unshift @getId()

        fn.apply model, newArgs

      create: (options = {}, cb = ->) ->
        @$isNew = false

        @execute 'create', options
          .asCallback cb

      destroy: (options = {}, cb = ->) ->
        @off()

        @execute 'destroyById', options
          .asCallback cb

      exists: (options = {}, cb = ->) ->
        @execute 'exists', options
          .asCallback cb

      save: (options = {}, cb = ->) ->
        if @$isNew
          action = 'create'
        else
          action = 'update'

        @[action] options
          .asCallback cb

      update: (options = {}, cb = ->) ->
        @execute 'updateById', options
          .asCallback cb

      updateAttributes: (data = {}, options = {}, cb = ->) ->
        @setAttributes data.toObject?() or data

        @save options
          .asCallback cb

  , 'model'