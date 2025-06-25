import { Machine, Sync, $end } from "@dashkite/talos"
import Email from "./email"
import Rune from "./rune"

When =
  usesEmail: ( talos ) ->
    talos.context.type == "email"

  usesRune: ( talos ) ->
    talos.context.type == "rune"


Run =
  determine: ( talos ) ->
    talos.context.type = ( Object.keys talos.context.literal )[ 0 ]

  noBuild: ( talos ) ->
    throw new Error "invalid authorization literal specified"

  emailBuilder: ( talos ) ->
    talos.context.result = Email.fromLiteral talos.context.literal.email
   
  runeBuilder: ( talos ) ->
    talos.context.result = Rune.fromLiteral talos.context.literal


machine = Machine.make "vega-client: authorization literal",
  start: "determine authorization type"
  
  "determine authorization type":
    run: Run.determine
    move: "select authorization builder"
  
  "select authorization builder":
    "use email builder": When.usesEmail
    "use rune builder": When.usesRune
    default: "unable to build"
  
  "unable to build": Run.noBuild
  "use email builder": Run.emailBuilder
  "use rune builder": Run.runeBuilder


Literal =
  start: ( context ) ->
    Sync.start machine, { context... }
      

export default Literal