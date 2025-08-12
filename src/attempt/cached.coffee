import { convert } from "@dashkite/sublime"
import Cache from "#helpers/cache"

cached = ( context ) ->

  yield name: "cached"

  # match against fetch API Request instance
  request = convert to: "fetch", context.request

  switch context.request.method

    when "put"
      # TODO construct anticipated response value from request
      Cache.put request, response

    when "delete"
      Cache.delete request

    else
      response = await Cache.get request
      if response?
        context.response = convert to: "sublime", response

  context

export default cached