import { metaclass } from "@dashkite/joy/metaclass"
import * as Time from "@dashkite/joy/time"

class Retries

  @descriptions:
    offline:
      limit: 3
    unauthorized:
      limit: 3
    "service unavailable":
      limit: 3
    "gateway timeout":
      limit: 3

  @increment: 200  # ms

  @growth: 2 # 2^n

  @make: ->
    counts = {}
    for key, description of @descriptions
      counts[ key ] = 0
    Object.assign ( new @ ), { counts }

  make: ( key ) -> Retry.make key, @

class Retry extends metaclass()

  @make: ( key, retries ) ->
    Object.assign ( new @ ), { key, retries }

  @getters
    canRetry: ->
      @retries.counts[ @key ] < Retries.descriptions[ @key ].limit

  increment: -> @retries.counts[ @key ]++

  wait: ->
    ( Retries.increment * 
      ( Math.pow Retries.growth, @retries.counts[ @key ] ))

  retry: ( options ) ->
    if @canRetry
      wait = @wait()
      @increment()
      yield { 
        name: ( options.name ? @key ), 
        wait, options.context... 
      }
      await Time.sleep wait
      true
    else
      false

export default Retries