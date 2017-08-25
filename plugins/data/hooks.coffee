module.exports = ->

  @factory 'ModelHooks', (debug, utils) ->
    { glob2re, wrap } = utils

    class Hook
      constructor: (fn) ->
        @fns = []

        if fn
          @observe fn

      observe: (fn) ->
        if Array.isArray fn
          i = 0

          while f = fn[i++]
            @observe f

          return @

        @fns.push fn

        @

      notify: (ctx, self, done) ->
        i = 0
        fns = @fns

        fail = (val) ->
          throw val

        next = (err) =>
          if err
            return (done or fail)(err)

          fn = fns[i++]

          if not fn
            return done()

          wrap(fn, next).apply self, [ ctx ]

          return

        next()

        @

    class ModelHooks
      constructor: (event, fn) ->
        if event and fn
          @observe event, fn

      fire: (event, ctx = {}, self = @, fn = ->) ->
        debug event

        if typeof self is 'function'
          return @fire event, {}, ctx, null, self
        
        if typeof ctx is 'function'
          return @fire event, {}, null, ctx

        { instance } = ctx.options?

        if event[0] isnt '$'
          event = '$' + event

        q = @defer fn

        evt = {}

        if instance
          evt = instance.$events?[event]

          instance.$property instance, event,
            value: true

        self = (err) =>
          if err
            return q.reject err

          @notify event, ctx, self, ->
            q.resolve ctx

        nested = (key, cb) ->
          inst = evt[key]
          inst.fire event, options, self, cb

        evts = Object.keys evt

        if evts?.length
          @each evts, nested, self
        else self()

        q.promise

      observe: (ev, fn) ->
        if Array.isArray ev
          ev.forEach (e) =>
            @observe e, fn
          
          return @

        @hooks = {}
        @evs = []
          
        if not @hooks[ev]
          @hooks[ev] = new Hook
          @evs.push ev 

        @hooks[ev].observe fn

        @

      removeAllListeners: (ev) ->
        if not ev
          @hooks = {}
          @evs = []
        else
          @hooks[ev] ?= []
          idx = @evs.indexOf ev 
          @evs.splice idx, 1

        @

      removeListener: (ev, fn) ->
        return @ unless @hooks[ev]

        evts = @hooks[ev].fns or [] 
        
        evts.forEach (e, i) =>
          if e is fn or e.fn is fn
            evts.splice i, 1

        return @ if evts.length 
        
        idx = @evs.indexOf ev 

        return @ if idx is -1 

        @evs.splice idx, 1

        @

      once: (ev, fn) ->
        return @ unless fn

        c = ->
          @removeListener ev, c
          fn arguments...

        c.fn = fn

        @on ev, c

        @

      notify: (ev, ctx, self = @, cb = ->) ->
        return unless @evs?.length

        re = glob2re ev
        
        i = 0
        fns = [] 

        @evs.forEach (hook) =>
          return unless re.test hook  
          
          fns.push @hooks[hook]...

        next = (err) =>
          if err
            return cb err

          fn = fns[i++]

          if not fn
            return cb()

          fn.notify ctx, self, next

          return

        next()

        @
