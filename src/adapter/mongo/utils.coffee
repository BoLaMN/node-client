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

