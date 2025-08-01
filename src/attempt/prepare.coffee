# TODO attach credentials

prepare = ( context ) ->
  yield name: "prepare"
  try
    context.request = await context.request.get()
  catch error
    # TODO handle error
    # TODO possibly create error response (ex: sky 405)
    # else re-throw
  context

export default prepare