import * as Time from "@dashkite/joy/time"
import { Authorization, WWWAuthenticate } from "@dashkite/http-headers"
import * as Client from "@dashkite/runes-client"
import Profile from "@dashkite/profile"
import { JSON64 } from "../utils"


Credentials =
  store: ( header ) ->
    authorization = Authorization.parse header
    switch authorization.scheme
      when "credentials"
        for value in JSON64.decode authorization.token
          Credentials.storeSingle Authorization.parse value 
      when "rune"
        Credentials.storeSingle authorization
      else
        throw new Error "unable to store credentials with scheme #{ scheme }"

  storeSingle: ({ scheme, parameters } = {}) ->
    switch scheme
      when "rune"
        Client.store 
          rune: parameters.rune
          nonce: parameters.nonce
      else
        throw new Error "unable to store credentials with scheme #{ scheme }"


  pull: ( context ) ->
    location = context.sublime.response.headers.get "location"
    loop
      response = await fetch location
      if response.status != 200
        throw new Error "received non 200 response from 401 location header"
      { status } = await response.json()
      if status == "success"
        header = response.headers.get "credentials"
        return Credentials.store header
      else
        await Time.sleep 1000 # wait one second

  parse: ( header ) ->
    authorization = Authorization.parse header
    if authorization.scheme == "credentials"
      values = JSON64.decode authorization.token
      Authorization.parse value for value in values
    else
      [ authorization ]

  # TODO: Do we need the second Profile.load for identity?
  prune: ( context ) ->
    { authorization } = context.sublime.request.headers
    { domain, resource, method } = context.sublime.response.content
    { email: identity } = do Profile.load
    Client.removeBound { identity, domain }
    credentials = Credentials.parse authorization
    for { scheme, parameters } in credentials when scheme == "rune"
      { rune, nonce } = parameters
      if Client.hasGrant rune, { domain, resource, method }
        { email: identity } = do Profile.load
        Client.remove { identity, domain, rune, nonce }
    

export default Credentials