import express from "express"
import cors from "cors"

Servers = 

  start: ->

    servers = [
      Promise.withResolvers()
      Promise.withResolvers()
    ]

    # set up simple local server so we can establish a base URL
    # for resolving relative paths
    express()
      .use express.static "build/browser", redirect: false
      .listen 3000, -> servers[0].resolve()

    express()

      .use cors
        origin: true
        methods: [ "get", "put", "post", "delete" ]
        allowedHeaders: [ "authorization", "content-type" ]
        exposedHeaders: [ "www-authenticate" ]
        # preflightContinue: false

      .get "/unauthorized", ( request, response ) ->

        console.log 
          method: request.method
          authorization: request.get "authorization"

        if ( request.get "authorization" ) == "foo 123"
          response
            .status 200
            .send "Hooray!"
        else
          response
            .set "www-authenticate": [ "foo" ]
            .status 401
            .send "Unauthorized"

      .listen 3001, -> servers[1].resolve()


    Promise.all servers.map ({ promise }) -> promise


export default Servers

