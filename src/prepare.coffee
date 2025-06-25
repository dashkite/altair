import * as Scout from "@dashkite/scout"

prepare = ( context ) ->
  yield name: "prepare"
  context.api = await Scout.discover context.url
  context

export default prepare