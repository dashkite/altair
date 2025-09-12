import Scout from "@dashkite/scout"
import { Rune, Credentials, Registry } from "@dashkite/sierra"

# Sky locator provider
provider =
  decode: ( url ) ->
    api = await Scout.discover url.origin
    Scout.decode url.target, api

registry = Registry.make()
registry.add "rune", Rune.make provider
registry.add "credentials", Credentials.make registry

export default registry