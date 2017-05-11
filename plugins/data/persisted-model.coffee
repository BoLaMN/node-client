module.exports = ->

  @factory 'PersistedModel', (Model, ObjectProxy, Utils, assert) ->
    { getArgs } = Utils

    class PersistedModel extends Model

      @create: (data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @create data, {}, options

        @execute 'create', data, options
          .asCallback cb

      @count: (query = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @count query, {}, options

        if not query.where
          query = where: query

        @execute 'count', query, options
          .asCallback cb

      @destroy: (query = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @destroy query, {}, options

        if not query.where
          query = where: query

        @execute 'destroy', query, options
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

        query = where:
          id: id

        @execute 'count', query, options
          .then (data) -> not not data
          .asCallback cb

      @execute: (command, args...) ->
        argNames = getArgs @dao[command]

        ctx = {}

        for arg, idx in argNames
          ctx[arg] = args[idx]

        fns = [
          => @fire 'before ' + command, ctx
          => @dao[command].apply @dao, args
          (res) =>
            ctx.result = res
            @fire 'after ' + command, ctx
        ]

        current = Promise.resolve()

        promises = fns.map (fn, i) ->
          current = current.then (res) ->
            fn res
          current

        cb = ctx.cb or ->

        Promise.all promises
          .then -> ctx.result
          .asCallback cb

      @find: (query = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @find query, {}, options

        if typeof query is 'function'
          return @find {}, {}, query

        @execute 'find', query, options
          .asCallback cb

      @findOne: (query = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findOne query, {}, options

        if not query.where
          query = where: query

        @execute 'findOne', query, options
          .asCallback cb

      @findById: (id, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findById id, {}, options

        assert id, 'The id argument is required'

        query = where:
          id: id

        @execute 'findOne', query, options
          .asCallback cb

      @findByIds: (ids = [], options = {}, cb = ->) ->
        if typeof options is 'function'
          return @findByIds ids, {}, options

        assert ids.length, 'The ids argument is requires ids'

        query = where:
          id: inq: ids

        @find query, options
          .asCallback cb

      @update: (query = {}, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateAll query, data, {}, options

        @execute 'update', query, data, options
          .asCallback cb

      @updateById: (id, data = {}, options = {}, cb = ->) ->
        if typeof options is 'function'
          return @updateById id, data, {}, options

        assert id, 'The id argument is required'

        query = where:
          id: id

        @update query, data, options
          .asCallback cb

      constructor: (data = {}, options = {}) ->
        super

        @on '*', (event, path, value, id) =>
          @$events[event] ?= {}

          if event is '$index'
            @$events[event][path] ?= {}
            @$events[event][path][value] ?= []
            @$events[event][path][value].push id
          else
            @$events[event][path] = value

        proxy = new ObjectProxy @, @$path, @$parent

        @setAttributes data, proxy

        return proxy

      setAttributes: (data = {}, proxy = @) ->
        if data.id and @constructor.primaryKey isnt 'id'
          @setId data.id
          delete data.id

        if data._id
          @setId data._id
          delete data._id

        for key, value of data
          if typeof proxy[key] is 'function'
            continue if typeof value is 'function'
            proxy[key](value)
          else
            proxy[key] = value

        if @$parent and @$path and not @$loaded
          @$parent.emit '$loaded', @$path, @

        @

      execute: (command, args...) ->
        argNames = getArgs @constructor[command]

        options = argNames.indexOf 'options'

        if options > -1
          args[options - 1].instance = @

        data = argNames.indexOf 'data'

        if data > -1
          args.splice data - 1, 0, @

        if argNames[0] is 'id'
          args.unshift @getId()

        @constructor[command].apply @constructor, args

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
