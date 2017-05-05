'use strict'

module.exports = ->

  @require 'moment'

  @provider 'log', (path, fs, moment, settings) ->
    { sprintf } = require 'sprintf-js'

    targets = []
    methods = [ 'log', 'info', 'warn', 'error' ]

    logInterface = {}

    defaults =
      log: true
      info: true
      warn: true
      error: true

    methods.forEach (method) ->
      logInterface[method] = ->
        args = arguments

        targets.forEach (target) ->
          if not target.restrictions[method]
            return

          target[method].apply(target, args)

    defaultRestrictions: (restrictions) ->
      obj = {}

      for key, value of defaults
        obj[key] = restrictions[key] or value

      obj

    addTarget: (target, restrictions) ->
      target.restrictions = @defaultRestrictions restrictions
      targets.push target

    addFileTarget: (file, restrictions) ->
      filePath = path.resolve settings.cwd, file

      stream = fs.createWriteStream filePath,
        flags: 'a',
        defaultEncoding: 'utf8'

      target = {}
      target.restrictions = @defaultRestrictions restrictions

      methods.forEach (method) ->
        target[method] = ->
          exp = sprintf.apply null, arguments

          stream.write moment().format('DD/MM/YYYY HH:mm:ss') + '\n' + method.toUpperCase() + ': '
          stream.write exp
          stream.write '\n\n'

      targets.push target

    $get: ->
      logInterface

  @config (logProvider) ->

    logProvider.addTarget console
