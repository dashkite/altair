import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"

ask = ( talos ) ->
  q = {}
  q.name = ( name ) -> talos.name == name
  q.state = ( name, state ) ->
    talos.name == name && talos.state == state

  q.failFrom = generic name: "vega-client: event ask question failFrom"
  generic q.failFrom, Type.isString, ( name ) ->
    talos.name == name && talos.failure
  generic q.failFrom, Type.isString, Type.isString, ( name, state ) ->
    talos.name == name && talos.failure && talos.previousState == state
  
  q.networkError = ->
      talos.failure && talos.error.message == "Failure to fetch"

  q


match = generic name: "vega-client: event match"

generic match, Type.isString, Type.isFunction, ( message, f ) ->
  when: ( talos ) -> f ask talos
  build: ( talos ) ->
    name: "announce"
    message: message
    value: talos

generic match, Type.isString, Type.isArray, ( message, fx ) ->
  when: ( talos ) ->
    _ask = ask talos
    fx.some ( f ) -> f _ask
  build: ( talos ) ->
    name: "announce"
    message: message
    value: talos 


Errors = [ 
  match "unable to parse resource description", ( ask ) ->
    ask.failFrom "resource", "parseResource"

  match "discovery failure", ( ask ) ->
    ask.failFrom "resource", "fetchAPIDescription"

  match "network failure", ( ask ) ->
    (ask.failFrom "resource") && ask.networkError()

  match "unable to match resource", ( ask ) ->
    ask.failFrom "make url", "resource"
  
  match "unable to match method", ( ask ) ->
    ask.failFrom "make url", "method"  

  match "unable to resolve target from bindings", ( ask ) ->
    ask.failFrom "make url", "target"

  match "unable to construct authorization header", ( ask ) ->
    ask.failFrom "headers", "authorization"
]


export default Errors