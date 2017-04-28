'use strict'

server = require('./core/Host').bootstrap()

if !module.parent
  server.run()
else
  module.exports = server