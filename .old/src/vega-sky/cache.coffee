import * as Time from "@dashkite/joy/time"

VegaCache = undefined

setEntryExpiration = ( url ) ->
  await Time.sleep 60 * 1000 # 60 seconds
  VegaCache.delete url


Cache =
  get: ( context ) ->
    VegaCache ?= await caches.open "vega-client"
    await VegaCache.match context.url.href
  
  matches: ( context ) ->
    ( await Cache.get context )?

  put: ( context ) ->
    VegaCache ?= await caches.open "vega-client"
    url = context.url.href
    body = context.body
    headers = 
      "content-type": context.headers[ "content-type" ]
      "content-length": "100"
    response = new Response body, { headers }
    VegaCache.put url, response
    setEntryExpiration url
    return  # Don't return above promise

  delete: ( context ) ->
    VegaCache ?= await caches.open "vega-client"
    url = context.url.href
    VegaCache.delete url
  
  writeback: ( context ) ->
    switch context.method
      when "put" then await Cache.put context
      when "delete" then await Cache.delete context


export default Cache