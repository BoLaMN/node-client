module.exports = ->

  @factory 'Events', (utils) ->
    { property } = utils

    iterate = (ev, fn) ->
      if not @$events
        return

      e = @$events[ev] or []
      i = e.length - 1

      while i >= 0 and e
        fn e[i] if e[i]
        i--

    id = 0

    class Events
      constructor: ->
        return

      add: (ev, cb) ->
        if not @$events
          property @, '$events',
            writable: true
            value: {}

        cb.id = id++

        @$events[ev] ?= []
        @$events[ev].push cb

        @$events[ev].length

      on: (ev, cb) ->
        @add ev, cb
        @

      off: (ev, cb) ->
        if not @$events?[ev]
          return

        itr = iterate.bind @

        itr ev, (e, i) =>
          if e is cb
            @$events[ev].splice i, 1

        if not @$events[ev]?.length
          delete @$events[ev]

      broadcast: (args...) ->
        itr = iterate.bind @

        itr '*', (e) =>
          e args...

        @

      emit: (ev, args...) ->
        itr = iterate.bind @

        itr ev, (e) =>
          e args...

        @broadcast ev, args...

        @

      once: (ev, cb) ->
        return @ if not cb

        c = =>
          @$events[ev].splice idx, 1
          cb arguments...

        idx = @add ev, c

        @
