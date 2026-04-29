class Server

  @servers = {}

  @make: ({ app, port }) -> Object.assign ( new @ ), { app, port }

  @add: ( name, app ) -> @servers[ name ] = @make app

  @start: ( names, port ) ->
    Promise.all do =>
      for name in names
        @servers[ name ].start()

  @stop: ( names ) -> 
    Promise.all do =>
      for name in names
        @servers[ name ].stop()

  start: ->
    { promise, resolve, @reject } = Promise.withResolvers()
    @server = @app.listen @port, resolve
    @server.on "error", ( error ) => @reject()
    promise

  stop: ->
    if @server?
      @server.closeAllConnections()
      { promise, resolve, @reject } = Promise.withResolvers()
      @server.close resolve
      @server = undefined
      promise

export default Server
