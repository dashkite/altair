import request from "./request"

class Altair

  @make: -> new @

  use: ( sublime ) ->
    @request = request sublime
    @

  get: ( specifier ) -> @request { method: "get", specifier... }

  put: ( specifier ) -> @request { method: "put", specifier... }

  delete: ( specifier ) -> @request { method: "delete", specifier... }

  post: ( specifier ) -> @request { method: "post", specifier... }

  patch: ( specifier ) -> @request { method: "patch", specifier... }

  head: ( specifier ) -> @request { method: "head", specifier... }

  options: ( specifier ) -> @request { method: "options", specifier... }

export default Altair
