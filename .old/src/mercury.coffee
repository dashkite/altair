import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import { Talos, Async } from "@dashkite/talos"

isURLSearchParams = Type.isType URLSearchParams
isURL = Type.isType URL


Mercury =
  context: Fn.curry ( context, talos ) ->
    talos.context = context

  origin: Fn.curry ( origin, talos ) ->
    talos.context.origin = origin

  target: Fn.curry ( target, talos ) ->
    talos.context.target = target

  url: Fn.curry ( url, talos ) ->
    if Type.isString url
      talos.context.url = new URL url
    else if isURL url
      talos.context.url = url

  method: Fn.curry ( method, talos ) ->
    talos.context.method = method.toUpperCase()

  headers: Fn.curry ( headers, talos ) ->
    talos.context.headers ?= {}
    Object.assign talos.context.headers, headers

  body: Fn.curry ( body, talos ) ->
    talos.context.body = body

  cors: Fn.curry ( cors, talos ) ->
    talos.context.cors = cors

  redirect: Fn.curry ( redirect, talos ) ->
    talos.context.redirect = redirect

  priority: Fn.curry ( priority, talos ) ->
    talos.context.priority = priority

  make: ( talos ) ->
    c = talos.context
    
    if !c.url?
      if !c.origin?
        throw new Error "no origin specified"
      c.target ?= "/"
      talos.context.url = new URL c.target, c.origin
    
    talos.context.request =
      method: c.method ? "GET"
      headers: c.headers ? {}
      mode: c.cors ? "cors"
      body: c.body
      redirect: c.redirect ? "follow"
      priority: c.priority ? "auto"

  issue: ( talos ) ->
    { url, request } = talos.context 
    talos.context.response = await fetch url.href, request

  status: Fn.curry ( status, talos ) ->
    if talos.context.response.status != status
      throw new Error "unexpected response status"
  
  json: ( talos ) ->
    talos.context.json = await talos.context.response.json()

  start: ( fx ) ->
    for await talos from Async.start fx, {}
      talos.name = "mercury"
      yield talos


export default Mercury