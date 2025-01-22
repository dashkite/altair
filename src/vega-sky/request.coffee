import { Async, Machine, $end } from "@dashkite/talos"
import Sky from "../sky"
import Headers from "./headers"
import Cache from "./cache"


Run =
  headers: ( talos ) ->
    for await current from Headers.start talos.context
      yield current
    if current.failure
      throw current.error

  writeback: ( talos ) ->
    Cache.writeback talos.context


Request = 
  start: ( context ) ->
    Async.start Machine.make "vega-client: make request", [
      "context", Sky.context authorization: context.authorization
      "origin", Sky.origin context.origin
      "api", Sky.api context.api
      "resource", Sky.resource context.name
      "method", Sky.method context.method
      "target", Sky.target context.bindings
      "url", Sky.url
      "content", Sky.content context.content
      "headers", Run.headers
      "writeback", Run.writeback
      "make", Sky.make
    ]


export default Request