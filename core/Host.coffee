'use strict'

injector = require './injectorInstance'

Registry = require './Registry'

registry = Symbol()

class Host

  constructor: (options) ->
    @[registry] = new Registry options

  @bootstrap: (options) ->
    host = new Host options

    host[registry]
      .core()
      .glob()
      .require()
      .resolve()
      .prioritize()
      .initialize()

    host

  run: ->
    @injector = injector
    @[registry].start()
    @injector

  inspect: ->
    @[registry]

module.exports = Host
