import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"

export default ({ origin }) -> [

  subtest "server error", ->
    events = HTTP.get {
      origin
      target: "/flakey/server-error"
    }
    
    # 0. Cache miss and first retry
    await advance events, [ "cache-miss", "retry" ]
    
    # 2. Second attempt succeeds (200)
    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status
    
    await advance events, [ "success", "done" ]

  subtest "too many requests (429)", ->
    events = HTTP.get {
      origin
      target: "/too-many-requests/retries"
    }
    
    # 0. Cache miss and first retry
    await advance events, [ "cache-miss", "retry" ]
    
    # 2. Second attempt succeeds (200)
    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status
    
    await advance events, [ "success", "done" ]

  subtest "gateway timeout (504)", ->
    events = HTTP.get {
      origin
      target: "/gateway-timeout/retries"
    }
    
    # 0. Cache miss and first retry
    await advance events, [ "cache-miss", "retry" ]
    
    # 2. Second attempt succeeds (200)
    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status
    
    await advance events, [ "success", "done" ]
]
