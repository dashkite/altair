import Retry from "./retry"

class Counter extends Retry

  @make: ({ limit } = {}) ->
    limit ?= 3
    count = 0
    Object.assign ( new @ ), { limit, count }

  @getters
    canRetry: -> @count < @limit
  
  retry: ->
    if @canRetry
      @count++
      true
    else false

export default Counter