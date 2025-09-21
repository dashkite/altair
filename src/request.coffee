import * as Fn from "@dashkite/joy/function"
import $convert from "@dashkite/sublime/convert"
import $cache from "./cache"
import Retries from "./retries"

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

    do ({ cache, request, response,
      retries, retry, _retries, limit } = {}) ->

      cache ?= await Cache.make "altair"

      request = $.Request.Builder.make specifier

      if ( response = await cache.match request )?

        response

      else

        retries = Retries.make()

        loop

          retry = false
          
          await cache.writethru request

          try
            response = await _run request

          catch error
            if navigator.onLine != true
              attempt = retries.make "offline"
              retry = await yield from attempt.retry context: { request }
              if retry then continue else throw error
            else
              yield { name: "error", error }
              break

          switch response?.description

            when "unauthorized"
              yield {
                name: "unauthorized"
                request, response
              }
              attempt = retries.make "unauthorized"
              if attempt.canRetry
                attempt.increment()
                challenges = ( response.headers.get "www-authenticate" ) ? []
                authenticated = yield { name: "authenticate", challenges }
                if authenticated == true
                  retry = true
                  request = 
                    $.Request.Builder
                      .make specifier
                      .update Fn.tee ( input ) ->
                        input.authorization = challenges

            when "too many requests"
              retry = yield {
                name: "too many requests", 
                request, response 
              }
              retry = ( retry == true )

            when "service unavailable", "gateway timeout"
              attempt = retries.make response.description
              options = name: "retry", context: { request }
              retry = await yield from attempt.retry options
              if !retry
                yield { 
                  name: response.description
                  request, response 
                }
            
            else
              yield {
                name: response.description
                request, response
              }

          break unless retry

        # If we have a real response--not from a cache
        # hit--remove the cached version from our temporary
        # cache. We also remove from our write-thru cache
        # since we by now have the actual response or the
        # original request has failed (in which case we want
        # to remove the cached entry anyway)
        cache.remove request
        
        if response?
          if response.ok
            yield { name: "success", response }
          else
            yield { name: "failure", response }

        response

export default request