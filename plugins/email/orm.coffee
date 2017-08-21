'use strict'

module.exports = ->

  @factory 'EmailORM', (env, fs, path, Connector, debug, assert) ->
    { join, resolve } = path

    template = require resolve(__dirname + '/email'), 'utf8'

    class Mailer 
      ###*
      # Send an email with the given `options`.
      #
      # Example Options:
      #
      # {
      #   from: "Fred Foo ✔ <foo@blurdybloop.com>", // sender address
      #   to: "bar@blurdybloop.com, baz@blurdybloop.com", // list of receivers
      #   subject: "Hello ✔", // Subject line
      #   text: "Hello world ✔", // plaintext body
      #   html: "<b>Hello world ✔</b>", // html body
      #   transport: "gmail", // See 'alias' option above in setupTransport
      # }
      #
      # See https://github.com/andris9/Nodemailer for other supported options.
      #
      # @param {Object} options
      # @param {Function} callback Called after the e-mail is sent or the sending failed
      ###

      @send: (options, fn) ->
        { settings, connector } = @dataSource?
        { EmailRequest } = @app.models 

        assert connector, 'Cannot send mail without a connector!'

        transport = connector.transportForName options.transport 
        
        if not transport
          transport = connector.defaultTransport()
        
        if debug.enabled or settings?.debug
          debug 'Sending Mail:'

          if options.transport
            debug '\u0009 TRANSPORT:%s', options.transport
          
          debug '\u0009 TO:%s', options.to
          debug '\u0009 FROM:%s', options.from
          debug '\u0009 SUBJECT:%s', options.subject
          debug '\u0009 TEXT:%s', options.text
          debug '\u0009 HTML:%s', options.html
        
        if transport
          assert transport.sendMail, 'You must supply an Email.settings.transports containing a valid transport'
          
          transport.sendMail options, (err, { MessageId } = {}) ->
            if err 
              return fn err 

            req =
              id: MessageId
              subject: options.subject 
              to: options.to
              from: options.from 
              
            EmailRequest.create req, callback

        else
          console.warn 'Warning: No email transport specified for sending email.' + 
                       ' Setup a transport to send mail messages.'
          
          process.nextTick ->
            fn null, options

        return

      ###*
      # Send an email instance using `modelInstance.send()`.
      ###

      send: (fn) ->
        @constructor.send @, fn

    class FakeMailer

      @MessageId: 0 

      @nextId: ->
        @MessageId++ 

      @send: (obj, cb) ->
        dir = join process.env.SERVER_DIR, '/emails/'
        now = new Date

        { EmailRequest } = @app.models 

        if not fs.existsSync dir
          fs.mkdirSync dir

        fName = now.getFullYear() + '_' + now.getMonth() + 1 + '_' + now.getDate() + '_' + now.getHours() + '_' + now.getMinutes() + '_' + now.getSeconds() + '_' + Math.floor(Math.random() * 100)
        fileName = join(dir, fName + '.json')
        
        email = {}

        for own key, val of obj 
          email[key] = val 

        email._ts = now.getTime()
        email_date = now 

        if email.html 
          email.html = encodeURI(email.html)

        fs.writeFileSync fileName, JSON.stringify(email, null, 4)
        
        emails = fs.readdirSync dir 
          .filter (name) -> name.match /\.json$/
          .map (name) -> join dir, name
          .map (file) -> require file
          .sort (b, a) -> a._ts - b._ts

        html = template emails 

        fs.writeFileSync join(dir, 'emails.html'), html
        
        req =
          id: @nextId()
          subject: options.subject 
          to: options.to
          from: options.from 
          
        EmailRequest.create req, cb
     
        return

      send: (fn) ->
        @constructor.send @, fn

    class EmailORM extends Connector
      constructor: (model) ->
        super

        @model = model
        @model.mixes if env.is 'dev' then FakeMailer else Mailer

