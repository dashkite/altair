import { convert } from "@dashkite/sublime"

request = ( context ) ->
  yield name: "request"
  context.response = await convert to: "sublime",
    await fetch convert to: "fetch", context.request
  yield name: "response", response: context.response
  context

export default request