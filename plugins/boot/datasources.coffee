module.exports = ->

  @provider 'datasources', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'datasources'

      configs = definition
      configs

  @run (debug, datasources, Adapters) ->

    Object.keys(datasources).forEach (key) ->
      datasource = datasources[key]
      
      debug 'datasources:' + key, datasource

      Adapters.get datasource.connector, (connector) ->
        connector.define key, datasource

    return
