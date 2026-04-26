import convert from "@dashkite/sublime/convert"

cache = ({ Request, Response }) ->

  class Cache

    @make: ( name ) ->
      cache = await caches.open name
      Object.assign ( new @ ), { name, cache }

    # we don't need to check the method here because the
    # browser does it for us
    match: ( request ) ->
      _response = await @cache.match await convert to: "fetch", request

      if _response?
        convert to: "sublime", _response

    writethru: ( request ) ->
      if request.method == "put"
        _request = await @cache.match await convert to: "fetch",
          Request.make {
            request.data...
            method: "get"
            content: undefined
          }
        _response = await convert "fetch",
          Response.make { status: 200, content: request.content }
        await @cache.put _request, _response

    remove: ( request ) ->
      @cache.delete await convert to: "fetch", request

export default cache
