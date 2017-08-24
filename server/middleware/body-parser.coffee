raw = require('raw-body')
inflate = require('inflation')
qs = require('qs')

module.exports = (opts = {}) ->
  strictJSONReg = /^[\x20\x09\x0a\x0d]*(\[|\{)/

  types = 
    'application/json': (str) ->
      return {} unless str

      if opts.strict and not strictJSONReg.test str
        throw new Error 'invalid JSON, only supports object and array' 

      JSON.parse str

    'text/plain': (str) ->
      str 

    'application/x-www-form-urlencoded': (str) ->
      qs.parse str, allowDots: true 

    'false': (str, type) ->
      message = if type then 'Unsupported content-type: ' + type else 'Missing content-type'

      err = new Error message 
      err.status = 415

      throw err

  (req, res) ->
    return Promise.resolve() unless req.headers['transfer-encoding'] isnt undefined or 
       not isNaN req.headers['content-length']

    type = req.headers['content-type'] or 'false'

    raw inflate(req), opts[type]
      .then (str) ->
        try
          req.body = types[type] str, type
        catch err
          err.status ?= 400
          err.body = str
          throw err