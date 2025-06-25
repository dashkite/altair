import * as Fn from "@dashkite/joy/function"
import * as URLCodex from "@dashkite/url-codex"
import { MediaType, Accept } from "@dashkite/media-type"
import { Async } from "@dashkite/talos"
import Mercury from "./mercury"

Sky =
  context: Fn.curry ( context, talos ) ->
    talos.context = context

  origin: Fn.curry ( origin, talos ) ->
    talos.context.origin = origin

  api: Fn.curry ( api, talos ) ->
    talos.context.api = api

  resource: Fn.curry ( name, talos ) ->
    if ( value = talos.context.api?.resources?[ name ] )?
      talos.context.name = name
      talos.context.resource = value
    else
      throw new Error "invalid resource #{ name }"

  method: Fn.curry ( name, talos ) ->
    talos.context.method = name
    if ( signatures = talos.context.resource?.methods?[ name ] )?
      talos.context.signatures = signatures
    else
      talos.context.failure = "method not allowed"

  target: Fn.curry ( bindings, talos ) ->
    if ( t = talos.context.resource?.template )?
      talos.context.target = URLCodex.encode t, bindings
    else
      throw new Error "URL template unavailable"

  url: ( talos ) ->
    c = talos.context
    if !c.origin?
      throw new Error "request origin unavailable"
    if !c.target?
      throw new Error "request target unavailable"

    talos.context.url = new URL c.target, c.origin

  content: Fn.curry ( content, talos ) ->
    if content?
      talos.context.content = content
      talos.context.body =
        switch MediaType.infer content
          when "json" then JSON.stringify content
          when "text" then content.toString()
          else content

  headers: Fn.curry ( headers, talos ) ->
    talos.context.headers = headers

  make: Mercury.make
  issue: Mercury.issue

  start: ( fx ) ->
    for await talos from Async.start fx, {}
      talos.name = "sky"
      yield talos
    return  # prevents accumulation


export default Sky