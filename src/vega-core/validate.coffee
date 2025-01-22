import { Async } from "@dashkite/talos"


Validate = 
  status: ( talos ) ->
    expected = talos.context.sublime.signatures?.response.status ? [ 200 ]
    { status } = talos.context.sublime.response
    if status not in expected
      throw new Error "unexpected response status"

  contentType: ( talos ) ->
    { response, signatures } = talos.context.sublime
    if response.content?
      expected = signatures.response?[ "content-type" ]
      expected ?= [ "application/json" ]
      type = response.headers.get "content-type"
      if type not in expected
        throw new Error "unexpected response content type"


Validate.response = Async.flow [
  Validate.status
  Validate.contentType
]
    

export default Validate