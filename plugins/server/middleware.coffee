'use strict'

module.exports = ->

  @run (api, HttpError, AccessHandler) ->

    api.use 'initial', (req, res, next) ->

      res.header = (field, val) ->
        if arguments.length == 2
          value = if Array.isArray(val) then val.map(String) else String(val)
          @setHeader field, value
        else
          for key of field
            @header key, field[key]

        @

      res.json = (json, headers = {}, code) ->
        try
          data = JSON.stringify(json)
        catch e
          console.error e
          return next new HttpError.InternalServerError 'Could not stringify JSON'

        if req.parsedUrl and req.parsedUrl.query.jsonp
          data = req.parsedUrl.query.jsonp + '(' + data + ')'

        headers["Content-Type"] = "application/json"

        res.header headers
        res.statusCode = code or 200
        res.end data

        return

      next()

    api.use 'auth', AccessHandler.check

    api.error (err, req, res, next) ->
      { code, statusCode } = err
      console.log err
      res.json err, {}, code or statusCode or 500

      return
