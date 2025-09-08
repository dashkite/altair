import { Machine, Sync, $end } from "@dashkite/talos" 
import Literal from "./literal"
import Email from "./email"
import Rune from "./rune"


When =
  hasLiteral: ( talos ) ->
    talos.context.sky.authorization?

  hasDefinitionSignature: ( talos ) ->
    talos.context.sky.signatures?.request?.authorization?

  usesEmail: ( talos ) ->
    talos.context.type == "email"

  usesRune: ( talos ) ->
    talos.context.type == "rune"

  success: ( talos ) ->
    talos.context.result?

  needsRetry: ( talos ) ->
    !( When.success talos ) && ( talos.context.allowed.length > 0 )
  

Run =
  fromLiteral: ( talos ) ->
    talos.context.literal = talos.context.sky.authorization
    for current from Literal.start talos.context
      yield current
    if current.failure
      throw current.error
    talos.context.result = current.context.result

  fromSignature: ( talos ) ->
    allowed = talos.context.sky.signatures.request.authorization
    talos.context.allowed = [ allowed... ]

  determine: ( talos ) ->
    talos.context.type = talos.context.allowed.shift()

  noBuild: ( talos ) ->
    throw new Error "unable to build the specified authorization header"

  emailBuilder: ( talos ) ->
    for current from Email.start talos.context
      yield current
    if current.success
      talos.context.result = current.context.result

  runeBuilder: ( talos ) ->
    for current from Rune.start talos.context
      yield current
    if current.success
      talos.context.result = current.context.result

machine = Machine.make "vega-client: headers-authorization",
  start:
    "use authorization literal": When.hasLiteral
    "use definition signature": When.hasDefinitionSignature
    default: $end
  
  "use authorization literal":
    run: Run.fromLiteral
    move: $end
  
  "use definition signature":
    run: Run.fromSignature
    move: "determine authorization type"
  
  "determine authorization type":
    run: Run.determine
    move: "select authorization builder"

  "select authorization builder":
    "use email builder": When.usesEmail
    "use rune builder": When.usesRune
    default: "unable to build"
  
  "unable to build": Run.noBuild
  
  "use email builder":
    run: Run.emailBuilder
    move: "confirm success"
  
  "use rune builder": 
    run: Run.runeBuilder
    move: "confirm success"

  "confirm success":
    [ $end ]: When.success
    "determine authorization type": When.needsRetry
    default: "unable to build"


Header =
  start: ( context ) ->
    Sync.start machine, sky: context


export default Header