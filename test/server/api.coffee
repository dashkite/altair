import express from "express"
import cors from "cors"
import { sleep } from "@dashkite/joy/time"

api = express()

api.use cors
  origin: true
  methods: [ "GET", "PUT", "POST", "DELETE", "PATCH", "HEAD", "OPTIONS" ]
  allowedHeaders: [ "authorization", "content-type", "accept" ]
  exposedHeaders: [ "location", "www-authenticate" ]

api
  .use express.json()
  .use express.text()

  .get "/status/:code/:id", ( request, response ) ->
    { id } = request.params
    response.status( parseInt request.params.code ).json { id }

  .get "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .put "/status/:code/:id", ( request, response ) ->
    { id } = request.params
    response.status( parseInt request.params.code ).json { id }

  .put "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .post "/status/:code", ( request, response ) ->
    if request.params.code == "201"
      response.set "location", "/status/200/9999"
    response.status( parseInt request.params.code ).send()

  .patch "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .head "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .options "/status/:code", ( request, response ) ->
    response.status( 204 ).send()

  .delete "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .get "/always-unauthorized", ( request, response ) ->
    response.set "www-authenticate", "Bearer"
    response.status( 401 ).send()

  .get "/json", ( request, response ) ->
    response.status( 200 ).json { greeting: { from: "Yours Truly" } }

  .get "/authorization", ( request, response ) ->
    if request.headers.authorization == "bearer secret"
      response.status( 200 ).json { message: "success" }
    else
      response.set "www-authenticate", "Bearer"
      response.status( 401 ).send()

  .get "/too-many-requests/:id", do ( counts = {}) -> 
    ( request, response ) ->
      { id } = request.params
      counts[ id ] ?= 0
      if (( counts[ id ] % 2 ) == 0 )
        response.status( 429 ).send()
      else
        response.status( 200 ).json { message: "success", id }
      counts[ id ]++

  .get "/gateway-timeout/:id", do ( counts = {}) -> 
    ( request, response ) ->
      { id } = request.params
      counts[ id ] ?= 0
      if (( counts[ id ] % 2 ) == 0 )
        response.status( 504 ).send()
      else
        response.status( 200 ).json { message: "success", id }
      counts[ id ]++

  .get "/flakey/:id", do ( counts = {}) -> 
    ( request, response ) ->
      { id } = request.params
      counts[ id ] ?= 0
      if counts[ id ]++ % 2 == 0
        response.status( 503 ).send()
      else
        response.status( 200 ).json { message: "success", id }

  .get "/malformed-json", ( request, response ) ->
    response
      .status 200
      .set "content-type", "application/json"
      .send "{ invalid: json "

  .get "/delay/:ms/:id", ( request, response ) ->
    response
      .status 200
      .json id: request.params.id

  .put "/delay/:ms/:id", ( request, response ) ->
    delay = parseInt request.params.ms
    await sleep delay
    response
      .status 200
      .json id: request.params.id

export default api