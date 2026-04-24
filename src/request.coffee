import * as Fn from "@dashkite/joy/function"
import $convert from "@dashkite/sublime/convert"
import $cache from "./cache"
import * as Retry from "@dashkite/retry"

request = ( $ ) ->

  Cache = $cache $

  convert = Fn.curry Fn.binary $convert

  _run = Fn.pipe  [
    convert to: "fetch"
    fetch
    convert to: "sublime"
  ]

  cache = undefined

  run = ( specifier ) ->
    do ( request = undefined ) ->

      try

        cache ?= await Cache.make "altair"

        request = $.Request.Builder.make specifier

        if ( response = await cache.match request )?
          yield { 
            name: response.description.toLowerCase().replace /\s+/g, "-"
            request, response 
          }
          yield { name: "success", request, response }
          response

        else

          retries =
            offline: Retry.Backoff.make()
            unauthorized: Retry.Counter.make()
            http: Retry.HTTP.make()

          loop

            retry = false
            
            await cache.writethru request

            try
              response = await _run request

            catch error
              if ( navigator.onLine != true )
                retry = await retries.offline.retry()
                continue
              else
                yield { name: "error", error }
                break

          switch response?.description

            when "unauthorized"
              if retries.unauthorized.retry()
                challenges = ( response.headers.get "www-authenticate" ) ? []
                authenticated = yield { name: "authenticate", challenges }
                if authenticated == true
                  retry = true
                  request = 
                    $.Request.Builder
                      .make specifier
                      .update Fn.tee ( input ) ->
                        input.authorization = challenges

            when "too many requests", "service unavailable", "gateway timeout"
              retry = await retries.http.retry response
            
          break unless retry
          request = ( yield { name: "retry", request }) ? request

        # If we have a real response--not from a cache
        # hit--remove the cached version from our temporary
        # cache. We also remove from our write-thru cache
        # since we by now have the actual response or the
        # original request has failed (in which case we want
        # to remove the cached entry anyway)
        await cache.remove request
        
        if response?

          yield { 
            name: response.description.toLowerCase().replace /\s+/g, "-"
            request, response 
          }

          if response.ok
            yield { name: "success", request, response }
          else
            yield { name: "failure", request, response }

        response

    catch error
      yield { name: "error", error }

export default request
