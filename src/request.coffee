import * as Fn from "@dashkite/joy/function"
import convert from "@dashkite/sublime/convert"
import cache from "./cache"
import * as Retry from "@dashkite/retry"

Normalize =
  name: ( string ) -> string.toLowerCase().replace /\s+/g, "-"
  error: ( error ) ->
    if ( match = error.message.match /^(?:Error:\s*)?sublime:\s*(.+)$/i )
      @name match[1]
    else
      "error"

Metal =

  run: do ( convert = Fn.curry Fn.binary convert ) ->
    Fn.pipe  [
      convert to: "fetch"
      fetch
      convert to: "sublime"
    ]  

request = ( sublime ) ->

  instance = Cache: cache sublime 

  do ({ Cache, cache } = instance ) ->

    { Request } = sublime
  
    lifecycle = scope: "request"

    run = ( specifier ) ->

      do ({
        request
        response
        scope
        name
        retry
        retries
        challenges
        authenticated
      } = lifecycle ) ->

        try

          cache ?= await Cache.make "altair"

          request = await Request.Builder
            .make specifier
            .get()

          if ( response = await cache.match request )?
            yield { name: "cache-hit", scope, request, response }
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

            await cache.writethru request

            loop

              retry = false
              scope = "request"
              
              try
                response = await Metal.run request

              catch error

                if ( globalThis.navigator?.onLine == false )

                  retry = await retries.offline.retry()
                  continue

                else

                  name = Normalize.error error
                  yield { name, scope, error }
                  break

              if response?

                scope = "response"
                name = Normalize.name response.description

                switch response.description

                  when "unauthorized"

                    yield { name, scope, request, response }

                    if retries.unauthorized.retry()
                      challenges = ( response.headers.get "www-authenticate" ) ? []
                      authenticated = yield { 
                        name: "authenticate"
                        scope: "request"
                        challenges 
                      }
                      if authenticated == true
                        retry = true
                        request = await Request.Builder
                          .make specifier
                          .update Fn.tee ( input ) ->
                            input.authorization = challenges
                          .get()

                  when "too many requests", "service unavailable", "gateway timeout"

                    retry = await retries.http.retry response

                    if !retry
                      yield { name, scope, request, response }

                  else
                    yield { name, scope, request, response }

              break unless retry
              yield { name: "retry", scope: "request", request }

            if response?

              await cache.remove request
            
              yield { 
                name: if response.ok then "success" else "failure"
                scope
                request
                response 
              }

              response

            else

              yield {
                name: "failure"
                scope
                request
              }

        catch error
          name = Normalize.error error
          yield { name, scope, error }
          yield { name: "failure", scope, request, error }

export default request
