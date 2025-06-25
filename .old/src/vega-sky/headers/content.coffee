import * as Fn from "@dashkite/joy/function"
import { MediaType, Accept } from "@dashkite/media-type"

# Because these are data APIs, we're going to assume JSON as a default.
getContentTypes = ( context ) ->
  if ( signature = context.signatures.request )?
    types = signature.content?.type
    types ?= signature[ "content-type" ]
    types ?= [ "application/json" ]
    types
  else
    throw new Error "request signature is unavailable"


Content =
  make: ( context ) ->
    candidates = getContentTypes context
    type = Accept.selectByContent context.content, candidates
    if type?
      context.headers[ "content-type" ] = MediaType.format type
    else
      throw new Error "content-type mismatch"


export default Content