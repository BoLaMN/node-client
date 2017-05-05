"use strict"

module.exports = ->

  @require 'nodemailer'

  @provider 'email', (nodemailer) ->

    transporters = {}

    addTransporter: (name, args...) ->
      transporters[name] = nodemailer.createTransport.apply nodemailer, args

    $get: ->
      (name) ->
        transporters[name]

