getArgs = (fn) ->
  fn
    .toString()
    .match(/function\s.*?\(([^)]*)\)/)[1]
  .split ','
  .map (arg) -> arg.replace(/\/\*.*\*\//, '').trim()
  .filter (arg) -> arg

module.exports = getArgs