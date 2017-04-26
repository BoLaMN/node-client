{ ObjectId } = require 'mongodb'
{ Type } = require '../../type'

exports.parseUpdateData = (data) ->
  parsedData = {}

  acceptedOperators = [
    '$currentDate'
    '$inc'
    '$max'
    '$min'
    '$mul'
    '$rename'
    '$setOnInsert'
    '$set'
    '$unset'
    '$addToSet'
    '$pop'
    '$pullAll'
    '$pull'
    '$pushAll'
    '$push'
    '$bit'
  ]

  usedOperators = 0
  i = 0

  while i < acceptedOperators.length
    if data[acceptedOperators[i]]
      parsedData[acceptedOperators[i]] = data[acceptedOperators[i]]
      usedOperators++
    i++

  if not usedOperators
    parsedData.$set = data

  parsedData

class exports.ObjectID extends Type
  @cast: (v) ->
    return if @absent v

    if v._bsontype is 'ObjectID' or v instanceof ObjectId
      return v

    if v.match /^[a-fA-F0-9]{24}$/
      return new ObjectId v
