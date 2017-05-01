'use strict'

module.exports = ->

  @factory 'Middleware', (HttpError) ->

    defaults: (req, res, next) ->

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

    describeApi: (root) ->
      (req, res, next) ->
        res.json root.describe()
