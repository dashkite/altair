import * as Type from "@dashkite/joy/type"
import { generic } from "@dashkite/joy/generic"
import { Talos } from "@dashkite/talos"
import Get from "./get"

When = 

  "request is ready": ( talos ) ->
      When.state talos, "vega-sky", "issue the request"

  "authorization scheme is email": ( talos ) ->
      "email" == ( Get[ "authorization scheme" ] talos )

  success: ( talos ) ->
    ( When.name talos, "issue" ) && talos.success
  
  failure: ( talos ) ->
    ( When.name talos, "issue" ) && talos.failure

  "response content is json": ( talos ) ->
    ( When.success talos ) &&
      ( talos.context.sublime?.response?.contentCategory == "json" )

  "response content is text": ( talos ) ->
    ( When.success talos ) &&
      ( talos.context.sublime?.response?.contentCategory == "text" )

  "response content is a blob": ( talos ) ->
    ( When.success talos ) &&
      ( talos.context.sublime?.response?.contentCategory == "binary" )

  "response has content": ( talos ) ->
    ( When.success talos ) &&
      talos.context.sublime?.response?.content?

  name: ( talos, name ) -> 
    talos.name == "vega-client: #{ name }"
  
  state: ( talos, name, state ) ->
    ( When.name talos, name ) && talos.state == state

  previous: ( talos, state ) ->
    talos.previousState == state

  # TODO confirm that this is the right way to detect a network error
  "network error": ( talos ) ->
    talos.failure && talos.error.message == "Failure to fetch"

# TODO develop this idea further
# When.failFrom = generic name: "vega-client: When.failFrom"
# generic When.failFrom, Talos.isType, Type.isString,
#   ( talos, name ) ->
#     talos.failure && ( When.name talos, name )
# generic When.failFrom, Talos.isType, Type.isString, Type.isString,
#   ( talos, name, state ) ->
#     talos.failure && 
#       ( When.name talos, name ) && 
#       ( When.previous talos, state )
  
export default When
export { When }