import { Machine, Sync, $end } from "@dashkite/talos"
import { Authorization } from "@dashkite/http-headers"
import Profile from "@dashkite/profile"

When = 
  hasEmail: ( talos ) ->
    talos.context.email?


Run =
  read: ( talos ) ->
    { email } = do Profile.load
    talos.context.email = email

  noBuild: ( talos ) ->
    throw new Error "no email available"
  
  build: ( talos ) ->
    talos.context.result = Email.fromLiteral talos.context.email


machine = Machine.make "vega-client: email",
  start: "read email from local storage"

  "read email from local storage":
    run: Run.read
    move: "select authorization builder"

  "select authorization builder":
    "use email builder": When.hasEmail
    default: "unable to build"
  
  "unable to build": Run.noBuild
  "use email builder": Run.build


Email =
  start: ( context ) -> Sync.start machine, { context... }

  fromLiteral: ( email ) ->
    Authorization.format
      scheme: "email"
      parameters: { email }  


export default Email