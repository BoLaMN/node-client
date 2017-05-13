'use strict'

require 'require-cson'

path = require 'path'
server = require './core/Host'

if not module.parent
  server.bootstrap
    directories: [
      path.join __dirname, 'plugins'
      path.join process.cwd(), 'plugins'
    ]
  .run()
else

  ###
    require 'node-client'
      directories: [
        path.join __dirname, 'plugins'
        path.join process.cwd(), 'plugins'
      ]
    .run()

    or

    app = require 'node-client'

    options = directories: [
      path.join __dirname, 'plugins'
      path.join process.cwd(), 'plugins'
    ]

    app(options).run()
  ###

  module.exports = server.bootstrap