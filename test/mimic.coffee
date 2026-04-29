# set up fetch API
import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import { pipe, tee } from "@dashkite/joy/function"
import * as K from "@dashkite/katana"
import Mimic from "@dashkite/mimic"

import scenarios from "./scenarios"
import Server from "./server"

export default ( context ) ->

  { parallel, sequential } = await scenarios()

  await Server.start [ "api", "static" ]

  port = Server.servers[ "static" ].port
  results = []

  try
    await do pipe [
      Mimic.browser
      Mimic.page
      Mimic.console Mimic.report.console
      Mimic.error Mimic.report.error
      Mimic.goto "http://localhost:#{ port }/test/index.html"
      # ensure the page is loaded and JavaScript has executed
      Mimic.waitFor ( -> window.test? ), timeout: 5000
      Mimic.evaluate ->
        await window.test.parallel.run()
        window.test.results
      # Note: we are currently ignoring sequential tests in the browser 
      # because they require server manipulation which is complex over the bridge.
      K.peek ( _results ) -> results = _results
      K.down
      Mimic.close
    ]

  catch error
    throw error

  finally
    await Server.stop [ "api", "static" ]

  results