# TODO attach credentials

prepare = ( context ) ->
  yield name: "prepare"
  context.request = await context.request.get()
  # try
  # ...
  # TODO handle error
  # TODO possibly create error response (ex: sky 405)
  # catch error
  #   else re-throw
  #   provisional error "handling"
  context

export default prepare