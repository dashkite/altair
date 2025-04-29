import { Machine, Async, $end } from "@dashkite/talos"
import URL from "./url"
import Request from "./request"
import Response from "./response"
import Cache from "./cache"


When =
  usesGet: ( talos ) ->
    /^get$/i.test talos.context.method
  
  cached: ( talos ) ->
    ( When.usesGet talos ) && ( await Cache.matches talos.context )
    

Run =
  getURL: ( talos ) ->
    for await current from URL.make talos.context
      yield current
    if current.failure
      throw current.error
    talos.context.signatures = current.context.signatures
    talos.context.url = current.context.url

  readCache: ( talos ) ->
    talos.context._response = await Cache.get talos.context

  makeRequest: ( talos ) ->
    for await current from Request.start talos.context
      yield current
    if current.failure
      throw current.error
    talos.context.request = current.context.request

  issueRequest: ( talos ) ->
    url = talos.context.url.href
    request = talos.context.request
    talos.context._response = await fetch url, request

  processResponse: ( talos ) ->
    for await current from Response.start talos.context
      yield current
    if current.failure
      throw current.error
    talos.context.response = current.context.response


machine = Machine.make "vega-client: vega-sky",
  start: "make the request url"
  "make the request url":
    run: Run.getURL
    move: "check for cached response"
  "check for cached response":
    read:
      when: When.cached
      run: Run.readCache
      move: "process the response"
    default: "make the request description"
  "make the request description":
    run: Run.makeRequest
    move: "issue the request"
  "issue the request":
    run: Run.issueRequest
    move: "process the response"
  "process the response":
    run: Run.processResponse
    move: $end


issueRequest = ( context ) -> Async.start machine, context


VegaSky = {
  request: issueRequest
  machine
  URL
  Request
  Response
  Cache
}

export default VegaSky

export {
  issueRequest as request

  machine
  URL
  Request
  Response
  Cache
}