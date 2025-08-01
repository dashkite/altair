import { convert } from "@dashkite/sublime"

request = ( context ) ->
  yield name: "request"
  context.response = convert to: "sublime",
    await fetch convert to: "fetch", request
  yield name: "response", response: context.response
  context

export default request