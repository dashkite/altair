import * as Fn from "@dashkite/joy/function"
import Request from "@dashkite/sky-sublime/request"
import convert from "@dashkite/sublime/convert"
import Cache from "./cache"
import Retries from "./retries"

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

    request = Request.make specifier

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
            throw error

        switch response?.description

          when "unauthorized"
            attempt = retries.make "unauthorized"
            if attempt.canRetry
              attempt.increment()
              challenges = ( response.headers.get "www-authenticate" ) ? []
              authenticated = yield { name: "authenticate", challenges }
              if authenticated == true
                retry = true
                request = 
                  Request
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

        break unless retry

      # If we have a real response--not from a cache
      # hit--remove the cached version from our temporary
      # cache. We also remove from our write-thru cache
      # since we by now have the actual response or the
      # original request has failed (in which case we want
      # to remove the cached entry anyway)
      cache.remove request
      
      response

export default run