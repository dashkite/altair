import { Request } from "@dashkite/sky-sublime"

prepare = ( specifier ) ->
  context = request: Request.make specifier
  yield { name: "prepare", context }
  context

export default prepare