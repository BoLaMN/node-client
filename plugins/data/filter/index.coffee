###*
# Module dependencies.
###

debug = require('debug')('filter')

'use strict'

module.exports = (app) ->

  app

  .module 'Filter', []

  .initializer ->

    @include './mods'
    @include './ops'
    @include './eql'
    @include './filter'
    @include './dot'
    @include './type'
    @include './where'

    @factory 'Query', (Modifiers, Filter, Dot, Type, Where) ->
      (obj = {}, query = {}, update = {}, opts = {}) ->
        strict = not not opts.strict

        log = []

        if Object.keys(query).length
          match = filter obj, new Where(query)

        if not strict or false isnt match
          keys = Object.keys(update)
          transactions = []

          i = 0
          l = keys.length

          while i < l
            if mods[keys[i]]
              debug 'found modifier "%s"', keys[i]

              for key of update[keys[i]]
                pos = key.indexOf('.$.')

                if ~pos
                  prefix = key.substr(0, pos)
                  suffix = key.substr(pos + 3)

                  if match[prefix]
                    debug 'executing "%s" %s on first match within "%s"', key, keys[i], prefix
                    fn = mods[keys[i]](match[prefix][0], suffix, update[keys[i]][key])

                    if fn
                      index = dot.get(obj, prefix).indexOf(match[prefix][0])

                      fn.key = prefix + '.' + index + '.' + suffix
                      fn.op = keys[i]

                      transactions.push fn
                  else
                    debug 'ignoring "%s" %s - no matches within "%s"', key, keys[i], prefix
                else
                  fn = mods[keys[i]](obj, key, update[keys[i]][key])

                  if fn
                    fn.key = key
                    fn.op = keys[i]

                    transactions.push fn
            else
              debug 'skipping unknown modifier "%s"', keys[i]

            i++

          if transactions.length
            i = 0

            while i < transactions.length
              fn = transactions[i]
              val = fn()

              log.push
                op: fn.op
                key: fn.key
                value: val

              i++
        else
          debug 'no matches for query %j', query

        log
