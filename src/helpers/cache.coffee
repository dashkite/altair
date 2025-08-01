import * as Time from "@dashkite/joy/time"

VegaCache = undefined

# TODO Remove when we have full cache invalidation ready
#      This may go away once we can invalidate dependent
#      resources or we have caching policies that do so.
#      May survive as a default.

setEntryExpiration = ( request ) ->
  await Time.sleep 60 * 1000 # 60 seconds
  VegaCache.delete request

Cache =

  get: ( request ) ->
    VegaCache ?= await window.caches.open "vega-client"
    await VegaCache.match request
  
  matches: ( request ) ->
    ( await Cache.get request )?

  put: ( request, response ) ->
    VegaCache ?= await window.caches.open "vega-client"
    VegaCache.put request, response
    setEntryExpiration request
    return  # Don't return above promise

  delete: ( request ) ->
    VegaCache ?= await window.caches.open "vega-client"
    VegaCache.delete request
  
export default Cache