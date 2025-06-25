import * as Obj from "@dashkite/joy/object"
import Generic from "@dashkite/generic"
import prepare from "./prepare"
import attempt from "./attempt"
import finalize from "./finalize"
import viable from "./viable"

normalize = do ->

  Generic.make "_normalize"

    .define [ Obj.has "url" ], ({ url }) -> { url}

    .define [ Obj.has "origin" ], ({ origin, target }) ->
      url: new URL ( if target? then "#{ origin }#{ target }" else origin )

    .define [ URL ], ( url ) -> { url }

    .define [ String ], ( url ) -> url: new URL text

HTTP =

  get: ( context ) -> 
    HTTP.request { method: "get", ( normalize context )... }

  put: ( context ) -> 
    HTTP.request { method: "put", ( normalize context )... }

  delete: ( context ) -> 
    HTTP.request { method: "delete", ( normalize context )... }

  post: ( context ) -> 
    HTTP.request { method: "post", ( normalize context )... }

  request: ( context ) ->
    context = yield from prepare context
    while viable context
      context = await yield from attempt context
    yield from finalize context
    yield { name: "response", context }

export default HTTP