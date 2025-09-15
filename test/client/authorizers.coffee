import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"

authorizers = Sierra.make()

authorizers.add "foo", 
  matches: -> true
  get: -> 
    scheme: "foo"
    token: "123"

Registry.set "authorizers", authorizers
