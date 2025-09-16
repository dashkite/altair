import express from "express"
import cors from "cors"
import * as Text from "@dashkite/joy/text"

import api from "./api"

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
        methods: [ "GET", "PUT", "POST", "DELETE" ]
        allowedHeaders: [ "authorization", "content-type" ]
        exposedHeaders: [ "www-authenticate" ]
        # preflightContinue: false

      .use express.text()

      .use express.json()

      .get "/status/:status", ( request, response ) ->
        response
          .status Text.parseNumber request.params.status
          .send "Status: #{ request.params.status }"

      .put "/status/:status", ( request, response ) ->
        response
          .status Text.parseNumber request.params.status
          .send request.body

      .get "/json", ( request, response ) ->
        response
          .status 200
          .json
            greeting:
              content: "Hello, world"
              from: "Yours Truly"

      .post "/post", ( request, response ) ->
        response
          .status 200
          .send "OK"
      
      .delete "/delete", ( request, response ) ->
        response
          .status 200
          .send "OK"
      
      .get "/authorized", ( request, response ) ->

        if ( request.get "authorization" ) == "foo 123"
          response
            .status 200
            .send "Hooray!"
        else
          response
            .set "www-authenticate": [ "foo" ]
            .status 401
            .send "Unauthorized"

      #
      # Sky Extensions Start Here
      #

      .get "/", ( request, response ) ->
        response
          .status 200
          .json api


      .get "/greeting/:name", ( request, response ) ->
        response
          .status 200
          .json greeting: "Hello"
            

      .put "/greeting/:name", ( request, response ) ->

        console.log response.body

        response
          .status 200
          .json response.body

      .listen 3001, -> servers[1].resolve()




    Promise.all servers.map ({ promise }) -> promise


export default Servers

