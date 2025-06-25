request = ( context ) ->
  yield name: "request"
  { url, method, headers, cors } = context
  context.response = await fetch { url, method, headers, cors }
  yield name: "response", response: context.response
  context

export default request