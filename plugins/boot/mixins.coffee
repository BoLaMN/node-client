module.exports = ->

  @provider 'mixins', ->
    configs = {} 

    @$get = (config) ->
      { definition } = config.one 'model-config'

      dirs = definition._meta.mixins 
      
      configs = config.from [ '**' ], dirs    
      configs

  @run (mixins, Mixins, debug) ->

    Object.keys(mixins).forEach (key) ->
      mixin = mixins[key]
      
      debug 'mixins:' + key, mixin 

      Mixins.define key, mixin

    return
