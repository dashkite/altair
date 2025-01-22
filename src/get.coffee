Get =
  
  "failure error": ( talos ) -> talos.error

  "response json": ( talos ) -> 
    talos.context.sublime.response.content

  "response text": ( talos ) ->
    talos.context.sublime.response.content

  "response blob": ( talos ) ->
    talos.context.sublime.response.content

  "response content": ( talos ) ->
    talos.context.sublime.response.content

  "request authorization": ( talos ) ->
    if ( authorization = talos.context.request.headers.authorization )?
      [ scheme, credential ] = authorization.split /\s+/
      { scheme, credential }

  "authorization scheme": ( talos ) ->
    ( Get[ "request authorization" ] talos )?.scheme

export default Get
export { Get }