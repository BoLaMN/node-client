module.exports = ->

  @provider 'datasources', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'datasources'

      configs = definition
      configs

  @run (debug, datasources, injector) ->

    Object.keys(datasources).forEach (key) ->
      datasource = datasources[key]
      
      debug 'datasources:' + key, datasource

      connector = injector.get datasource.connector 
      connector.define key, datasource

    return
