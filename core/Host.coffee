'use strict'

injector = require './injectorInstance'

Registry = require './Registry'

class Host

  constructor: ->
    @registry = new Registry()

  @bootstrap: ->
    host = new Host

    host.registry
      .glob()
      .require()
      .resolve()
      .prioritize()
      .initialize()

    host

  run: ->
    injector.get 'main'
    @registry.start()

module.exports = Host
