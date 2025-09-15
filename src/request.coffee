import * as Fn from "@dashkite/joy/function"
import * as Time from "@dashkite/joy/time"
import Request from "@dashkite/sky-sublime/request"
# import convert from "@dashkite/sky-sublime/convert"
import convert from "@dashkite/sublime/convert"
import Cache from "./cache"

Retries =
  unauthorized:
    limit: 3

_run = Fn.pipe  [
  convert to: "fetch"
  fetch
  convert to: "sublime"
]

cache = undefined

run = ( specifier ) ->

  cache ?= await Cache.make "altair"

  request = Request.make specifier

  if ( response = await cache.match request )?

    response

  else

    retries =
      unauthorized: 0

    loop

      retry = false
      
      await cache.writethru request

      try
        response = await _run request

      catch error
        # TODO retry logic  
        # for now, just log the message
        console.error error.message
        if window.configuration.debug == true
          console.error error.stack

      switch response?.description
        
        when "unauthorized"
          if ( retries.unauthorized++ < Retries.unauthorized.limit )          
            challenges = ( response.headers.get "www-authenticate" ) ? []
            authorization = yield { name: "authenticate", challenges }
            if authorization?
              retry = true
              request = 
                Request
                  .make specifier
                  .update Fn.tee ( input ) ->
                    input.authorization = authorization

      break unless retry

    # If we have a real response--not from a cache
    # hit--remove the cached version from our temporary
    # cache. We also remove from our write-thru cache since
    # we by now have the actual response or the original
    # request has failed (in which case we want to remove
    # the cached entry anyway)
    cache.remove request
    
    response

export default run