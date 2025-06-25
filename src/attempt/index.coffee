import cached from "./cached"
import prepare from "./prepare"
import request from "./request"
import finalize from "./finalize"

attempt = ( context ) ->
  yield name: "attempt"
  context = yield from cached context
  if context.response?
    context
  else
    context = yield from prepare context
    context = await yield from request context
    context = yield from finalize context
    context

export default attempt