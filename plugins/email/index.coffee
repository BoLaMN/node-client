module.exports = (app) ->

  app

  .module 'EmailConnector', [ 'Connector', 'Type' ]

  .initializer ->

    @require [
      'nodemailer'
    ]

    @include './orm'

    @connector 'Email', (EmailORM, nodemailer) ->
      class Email extends EmailORM

        @initialize: (@settings = {}, fn = ->) ->
          super 

          transports = @settings.transports
          
          if !transports and @settings.transport
            transports = [ @settings.transport ]
          
          if !transports
            transports = []
          
          @transportsIndex = {}
          @transports = []
          
          transports.forEach @setupTransport.bind(this)
       
          @connect().asCallback fn
        
        @connect: ->
          @connecting = true
          @connected = true

          Promise.resolve()

        @disconnect: (callback) ->
          debug 'disconnect'

          if callback
            process.nextTick callback

        @toString: ->
          @name

        ###*
        # Add a transport to the available transports. See https://github.com/andris9/Nodemailer#setting-up-a-transport-method.
        #
        # Example:
        #
        #   Email.setupTransport({
        #       type: "SMTP",
        #       host: "smtp.gmail.com", // hostname
        #       secureConnection: true, // use SSL
        #       port: 465, // port for secure SMTP
        #       alias: "gmail", // optional alias for use with 'transport' option when sending
        #       auth: {
        #           user: "gmail.user@gmail.com",
        #           pass: "userpass"
        #       }
        #   });
        #
        ###

        @setupTransport: (setting) ->
          @transports = @transports or []
          @transportsIndex = @transportsIndex or {}
          
          transport = undefined
          transportType = (setting.type or 'STUB').toLowerCase()
          
          if transportType == 'direct'
            transport = nodemailer.createTransport()
          else if transportType == 'smtp'
            transport = nodemailer.createTransport(setting)
          else
            transportModuleName = 'nodemailer-' + transportType + '-transport'
            transportModule = require(transportModuleName)
          
            transport = nodemailer.createTransport(transportModule(setting))
          
          @transportsIndex[setting.alias or setting.type] = transport
          @transports.push transport
          
          return

        ###*
        # Get a transport by name.
        #
        # @param {String} name
        # @return {Transport} transport
        ###

        @transportForName: (name) ->
          @transportsIndex[name]

        ###*
        # Get the default transport.
        #
        # @return {Transport} transport
        ###

        @defaultTransport: ->
          @transports[0] or @stubTransport

