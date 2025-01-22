import { Async, Machine } from "@dashkite/talos"
import Mercury from "./mercury"


APIDescription = 
  start: ({ origin, discoveryTarget }) ->
    Async.start Machine.make "vega-client: discover", [
      "origin", Mercury.origin origin
      "target", Mercury.target discoveryTarget
      "method", Mercury.method "get"
      "headers", Mercury.headers accept: "application/json"
      "make", Mercury.make
      "issue", Mercury.issue
      "status", Mercury.status 200
      "json", Mercury.json
    ]


export default APIDescription