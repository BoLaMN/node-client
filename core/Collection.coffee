'use strict'

{ values } = require './Utils'

class Collection extends Array

  constructor: (collection) ->
    super

    values(collection).forEach (item) =>
      @push item

module.exports = Collection