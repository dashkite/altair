import { Machine, Async, $end } from "@dashkite/talos"
import * as Arr from "@dashkite/joy/array"
import * as Text from "@dashkite/joy/text"
import * as It from "@dashkite/joy/iterable"
import { MediaType } from "@dashkite/media-type"


When =

  hasContent: ( talos ) ->
    ( talos.context.response.headers.get "content-type" )? &&
      (( !( talos.context.response.headers.get "content-length" )? ||
        (( talos.context.response.headers.get "content-length" ) > 0 )))

Run =
  parseBasics: ( talos ) ->
    r = talos.context._response
    talos.context.response =
      status: r.status
      headers: do ({ headers } = {}) ->
        headers = r.headers
        get: ( name ) ->
          if ( value = headers.get name )?
            values = It.map Text.trim, Text.split ",", value
            values[ 0 ]

  parseContent: ( talos ) ->
    { response, _response } = talos.context
    type = response.headers.get "content-type"
    category = MediaType.category type
    talos.context.response.contentCategory = category
    talos.context.response.content =
      switch category
        when "json" then await _response.json()
        when "text" then await _response.text()
        when "binary" then await _response.blob()
        else null


machine = Machine.make "vega-client: process response",
  start: "basics"
  basics:
    run: Run.parseBasics
    move: "content"
  content:
    hasContent:
      when: When.hasContent
      run: Run.parseContent
      move: $end
    default: $end


Response =
  start: ({ _response }) -> Async.start machine, { _response }


export default Response