import * as Fn from "@dashkite/joy/function"
import { Machine, Async, $end } from "@dashkite/talos"
import Content from "./content"
import Authorization from "./authorization"


Run =
  setup: ( talos ) ->
    talos.context.headers = {}

  content: ( talos ) ->
    if talos.context.content?
      talos.context.headers[ "content-type" ] = Content.make talos.context

  authorization: ( talos ) ->
    for await current from Authorization.start talos.context
      yield current
    if current.failure
      throw current.error
    if current.context.result?
      talos.context.headers.authorization = current.context.result


machine = Machine.make "vega-client: headers",
  start:
    run: Run.setup
    move: "content"
  content:
    run: Run.content
    move: "authorization"
  authorization:
    run: Run.authorization
    move: $end


Headers =
  start: ( context ) -> Async.start machine, context


export default Headers