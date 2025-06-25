import { Machine, Sync, $end } from "@dashkite/talos"
import { Authorization } from "@dashkite/http-headers"
import * as Runes from "@dashkite/runes-client"
import Credentials from "@dashkite/sierra"

When = {}


Run =
  prepare: ( talos ) ->
    { name, method, url } = talos.context.sky
    domain = url.hostname
    talos.context.resource = { domain, name, method }

  build: ( talos ) ->
    type = "rune"
    { resource } = talos.context 
    for current from Credentials.Build.start { type, resource }
      yield current
    if current.failure
      throw current.error
    talos.context.result = current.context.credentials


machine = Machine.make "vega-client: rune",
  start: "build rune resource reference"
  "build rune resource reference":
    run: Run.prepare
    move: "build rune credentials"
  "build rune credentials":
    run: Run.build
    move: $end


Rune =
  start: ( context ) ->
    Sync.start machine, { context... }

  fromLiteral: ( literal ) ->
    Authorization.format
      scheme: "rune"
      parameters:
        rune: literal.rune
        nonce: literal.nonce
      

export default Rune