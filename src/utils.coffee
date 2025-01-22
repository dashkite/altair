import { confidential } from "panda-confidential"

Confidential = confidential()

# TODO add to bake
JSON64 =

  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 4
  encode: (value) ->
    Confidential.convert
      from: "utf8"
      to: "base64"
      JSON.stringify value
  
  decode: (value) ->
    converted = Confidential.convert
      from: "base64"
      to: "utf8"
      value
    JSON.parse converted

export { JSON64 }