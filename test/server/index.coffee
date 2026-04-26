import express from "express"

app = express()

  .use express.json()
  .use express.text()

  .get "/status/:code/:id", ( request, response ) ->
    { id } = request.params
    response.status( parseInt request.params.code ).json { id }

  .get "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .put "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .post "/status/:code", ( request, response ) ->
    if request.params.code == "201"
      response.set "location", "/status/200/9999"
    response.status( parseInt request.params.code ).send()

  .delete "/status/:code", ( request, response ) ->
    response.status( parseInt request.params.code ).send()

  .get "/json", ( request, response ) ->
    response.status( 200 ).json { greeting: { from: "Yours Truly" } }

  .get "/authorization", ( request, response ) ->
    if request.headers.authorization == "Bearer secret"
      response.status( 200 ).json { message: "success" }
    else
      response.set "www-authenticate", "Bearer"
      response.status( 401 ).send()

  .get "/flakey", do ( count = 0 ) -> 
    ( request, response ) ->
      if count++ < 2
        response.status( 503 ).send()
      else
        count = 0
        response.status( 200 ).json { message: "success" }

  #
  # Sky Extensions Start Here
  #

  # .get "/", ( request, response ) ->
  #   response
  #     .status 200
  #     .json api


  # .get "/greeting/:name", ( request, response ) ->
  #   response
  #     .status 200
  #     .json greeting: "Hello"
        

  # .put "/greeting/:name", ( request, response ) ->
  #   response
  #     .status 200
  #     .json response.body


Server =
  start: ( port ) ->
    new Promise ( resolve ) =>
      @_server = app.listen port, -> resolve()

  stop: ->
    new Promise ( resolve ) =>
      @_server.close -> resolve()

export default Server
