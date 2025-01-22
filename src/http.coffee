import Issue from "./issue"
import When from "./when"
import Get from "./get"

HTTP =
  start: Issue.start

  get: ( resource ) -> 
    Issue.start { method: "get", resource }

  put: ( resource, content ) -> 
    Issue.start { method: "put", resource, content }

  delete: ( resource ) -> 
    Issue.start { method: "delete", resource }

  post: ( resource, content ) -> 
    Issue.start { method: "post", resource, content }

  bind: ( reactor ) ->
    for await talos from reactor
      yield
        when: ( condition ) -> When[ condition ] talos
        get: ( target ) -> Get[ target ] talos
    return

export default HTTP