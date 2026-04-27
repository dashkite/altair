import convert from "@dashkite/sublime/convert"

cache = ({ Request, Response }) ->

  Synthetic =

    request: ( request ) ->
      { content, method, specifier... } = request.data
      convert to: "fetch",
        Request.Builder.make { specifier..., method: "get" }
    
    response: ( request ) ->
      convert to: "fetch",
        Response.Builder.make {
          request: request.data
          status: 200
          content: request.content
        }

  class Cache

    @make: ( name ) ->
      cache = await caches.open name
      Object.assign ( new @ ), { name, cache }

    match: ( request ) ->
      _request = await convert to: "fetch", request
      _response = await @cache.match _request

      if _response?
        convert to: "sublime", _response

    writethru: ( request ) ->
      switch request.method
        when "put"
          _request = await Synthetic.request request
          _response = await Synthetic.response request
          await @cache.put _request, _response
        when "delete"
          await @cache.delete await Synthetic.request request

    remove: ( request ) ->
      _request = await convert to: "fetch", request
      await @cache.delete _request
      switch request.method
        when "put", "delete"
          await @cache.delete await Synthetic.request request


export default cache
