'use strict'

injector = require './injectorInstance'

Registry = require './Registry'

registry = Symbol()

class Host

  constructor: ->
    @[registry] = new Registry()

  @bootstrap: ->
    host = new Host

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
