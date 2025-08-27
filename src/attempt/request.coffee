import * as Fn from "@dashkite/joy/function"
import { convert } from "@dashkite/sublime"

_request = Fn.pipe [
  convert to: "fetch"
  fetch
  convert to: "sublime"
]

request = ( context ) ->
  yield name: "request"
  context.response = await _request context.request
  yield name: "response", response: context.response
  context

export default request