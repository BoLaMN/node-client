module.exports = (app) ->

  @provider 'boots', ->
    configs = {}

    @$get = (config, path) ->
      dirs = app.directories.map (directory) ->
        path.join directory, 'boot'

      configs = config.from [ '**' ], dirs 
      configs

  @run (boots, debug) ->

    Object.keys(boots).forEach (key) ->
      boot = boots[key]
      boot.fn()

      debug 'boots:' + key, boot 

    return

