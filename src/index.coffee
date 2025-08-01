import * as Obj from "@dashkite/joy/object"
import Generic from "@dashkite/generic"
import prepare from "./prepare"
import attempt from "./attempt"
import done from "./done"
import finalize from "./finalize"

HTTP =

  get: ( specifier ) -> HTTP.request { method: "get", specifier... }

  put: ( specifier ) -> HTTP.request { method: "put", specifier... }

  delete: ( specifier ) -> HTTP.request { method: "delete", specifier... }

  post: ( specifier ) -> HTTP.request { method: "post", specifier... }

  request: ( specifier ) ->
    context = yield from prepare specifier
    while !( done context )
      context = await yield from attempt context
    yield from finalize context
    context.response

export default HTTP
