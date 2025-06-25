import * as Value from "@dashkite/joy/value"
import { Machine, Async, $end } from "@dashkite/talos"
import { Authorization, WWWAuthenticate } from "@dashkite/http-headers"
import HTTP from "../vega-sky"
import Credentials from "./credentials"
import Validate from "./validate"


When =
  canRetry: ( talos ) ->
    { status, headers } = talos.context.sublime.response
    if status != 401
      return false
    if !( header = headers.get "www-authenticate" )?
      return false
    directives = WWWAuthenticate.parse header
    directives = directives.map ({ scheme }) -> scheme
    "rune" in directives

  hasCredentials: ( talos ) ->
    { response } = talos.context.sublime
    ( response.headers.get "credentials" )?

  hasLocation: ( talos ) ->
    { headers } = talos.context.sublime.response
    ( headers.get "location" )?

  canPrune: ( talos ) ->
    { request, response } = talos.context.sublime
    if !request.headers.authorization?
      return false
    if response.contentCategory != "json"
      return false
    if !response.content?.domain?
      return false
    if !response.content?.resource?
      return false
    if !response.content?.method?
      return false
    true


Run =
  attempt: ( talos ) ->
    for await current from HTTP.request Value.clone talos.context.input
      yield current
    if current.failure
      throw current.error
    talos.context.sublime = current.context    

  storeCredentials: ( talos ) ->
    header = talos.context.sublime.response.headers.get "credentials"
    Credentials.store header

  pullCredentials: ( talos ) ->
    await Credentials.pull talos.context
    delete talos.context.input.authorization  # remove email auth literal

  pruneCredentials: ( talos ) ->
    await Credentials.prune talos.context

  validate: ( talos ) ->
    await Validate.response talos.context


machine = Machine.make "vega-client: core",
  start: "attempt"
  attempt:
    run: Run.attempt
    move: "authorization"
  authorization:
    retry: When.canRetry
    credentials:
      when: When.hasCredentials
      run: Run.storeCredentials
      move: "validate"
    default: "validate"
  retry:
    pullCredentials:
      priority: 1
      when: When.hasLocation  
      run: Run.pullCredentials
      move: "attempt"
    pruneCredentials:
      priority: 2
      when: When.canPrune
      run: Run.pruneCredentials
      move: "attempt"
    default: "validate"
  validate:
    run: Run.validate
    move: $end


request = ( context ) -> Async.start machine, input: context


Core = {
  request
}

export default Core
export {
  request
}