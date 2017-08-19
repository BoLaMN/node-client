module.exports = ->

  @provider 'connectors', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'connector-config'

      configs = config.from definition

      configs

  @run (connectors, Connectors, debug) ->

    Object.keys(connectors).forEach (key) ->
      config = connectors[key]

      if config.fn?.initialize
        connector = config.fn 
      else 
        connector = config.fn()

      debug 'connectors:' + key, config 
      
      Connectors.define key, connector
      
    return

