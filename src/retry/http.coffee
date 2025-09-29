import * as Time from "@dashkite/joy/time"
import * as Text from "@dashkite/joy/text"
import Backoff from "./backoff"

# adapted from ky [1]
getRetryHeader = ( response ) ->
  ( response.headers.get "retry-after" ) ?
    ( response.headers.get "ratelimit-reset" ) ?
    ( response.headers.get "x-ratelimit-reset" ) ?
    ( response.headers.get "x-rate-limit-reset" )

class HTTP extends Backoff

  retry: ( response ) ->
    wait = switch response.description
      when "content too large", "too many requests", "service unavailable"
        if ( after = getRetryHeader response )?
          if ( seconds = Text.parseNumber after ) != Number.isNaN
            # make sure this isn't a timestamp [1]
            ( seconds -= Date.now()) if ( seconds >= 1e9 )
            Math.min @cap, seconds * 1000
          else
            try (( Date.parse after ) - Data.now())
    wait ?= @wait
    await Time.sleep wait
    @counter++
    true

export default HTTP

# [1]: adapted from 
# https://github.com/sindresorhus/ky/blob/ac3e6149b449ad49e51e89543b1dc27e8bfba7bd/source/core/Ky.ts#L280