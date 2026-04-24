import * as Fn from "@dashkite/joy/function"
import $convert from "@dashkite/sublime/convert"
import $cache from "./cache"
import * as Retry from "@dashkite/retry"

Normalize =
  name: ( string ) -> string.toLowerCase().replace /\s+/g, "-"
  error: ( error ) ->
    if ( match = error.message.match /^(?:Error:\s*)?sublime:\s*(.+)$/i )
      @name match[1]
    else
      "error"

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

    # shadows the request function
    do ( request = undefined ) ->
      scope = "request"
      try

        cache ?= await Cache.make "altair"

        request = $.Request.Builder.make specifier

        if ( response = await cache.match request )?
          scope = "response"
          name = Normalize.name response.description
          yield { name, scope, request, response }
          yield { name: "success", scope, request, response }
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
              scope = "response"
            catch error
              scope = "request"
              if ( navigator.onLine != true )
                retry = await retries.offline.retry()
                continue
              else
                name = Normalize.error error
                yield { name, scope, error }
                break

            switch response?.description

              when "unauthorized"
                if retries.unauthorized.retry()
                  challenges = ( response.headers.get "www-authenticate" ) ? []
                  authenticated = yield { 
                    name: "authenticate"
                    scope: "request"
                    challenges 
                  }
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
            request = ( yield { name: "retry", scope: "request", request }) ? request

          await cache.remove request
          
          if response?
            scope = "response"
            name = Normalize.name response.description
            yield { name, scope, request, response }

            if response.ok
              yield { name: "success", scope, request, response }
            else
              yield { name: "failure", scope, request, response }

          response

      catch error
        name = Normalize.error error
        yield { name, scope, error }

export default request
