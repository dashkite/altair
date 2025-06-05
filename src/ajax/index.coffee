import Altair from "../index"


HTTP =

  get: ( locator ) ->
    for await event from ( Altair.bind Altair.get locator )
      if event.when "success"
        yield name: "success"
        value = event.get "response json"
        yield { name: "value", value, locator, method: "get" }
      else if event.when "method not allowed"
        yield { name: "method not allowed", method: ( event.get "method" )}
      else if event.when "failure"
        error = event.get "failure error"
        yield { name: "failure", error }
    return

  put: ( locator, _value ) ->
    for await event from ( Altair.bind Altair.put locator, _value )
      if event.when "success"
        yield name: "success"
        value = event.get "response json"
        yield { name: "value", value }
      else if event.when "failure"
        error = event.get "failure error"
        yield { name: "failure", error }
    return

  delete: ( locator ) ->
    for await event from ( Altair.bind Altair.delete locator )
      if event.when "success"
        yield { name: "success", method: "delete", locator }
      else if event.when "failure"
        error = event.get "failure error"
        yield { name: "failure", error }
    return

  post: ( locator, _value ) ->
    for await event from ( Altair.bind Altair.post locator, _value )
      if event.when "success"
        value = event.get "response json"
        if event.when "created"
          location = event.get "location"
          yield { name: "created", location, value }
          yield { name: "value", location, value }
        else
          # success?
          yield { name: "value", value }
      else if event.when "failure"
        error = event.get "failure error"
        yield { name: "failure", error }
    return

export default HTTP