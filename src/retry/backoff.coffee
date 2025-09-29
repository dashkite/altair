import * as Time from "@dashkite/joy/time"
import Retry from "./retry"

randomize = ( start, end  ) ->
  start + ( Math.floor ( Math.random() * ( end - start )))

class Backoff extends Retry

  @make: ({ delay, rate, cap } = {}) ->
    delay ?= 200
    rate ?= 2
    cap ?= 5 * 60 * 1000 # 5 minutes
    counter = 0
    Object.assign ( new @ ), { delay, rate, cap, counter }

  @getters
    wait: ->
      Math.min @cap,
        randomize @delay, 
          ( @delay * ( Math.pow @rate, @counter ))

  retry: ->
    await Time.sleep @wait
    @counter++
    true

export default Backoff


