import request from "./request"

HTTP =

  get: ( specifier ) -> HTTP.request { method: "get", specifier... }

  put: ( specifier ) -> HTTP.request { method: "put", specifier... }

  delete: ( specifier ) -> HTTP.request { method: "delete", specifier... }

  post: ( specifier ) -> HTTP.request { method: "post", specifier... }

  request: request

export default HTTP
