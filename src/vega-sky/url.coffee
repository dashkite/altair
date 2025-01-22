import { Async, Machine } from "@dashkite/talos"
import Sky from "../sky"


URL = 
  make: ( context ) ->
    Async.start Machine.make "vega-client: make url", [
      "origin", Sky.origin context.origin
      "api", Sky.api context.api
      "resource", Sky.resource context.name
      "method", Sky.method context.method
      "target", Sky.target context.bindings
      "url", Sky.url
    ]


export default URL