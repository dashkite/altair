# set up fetch API
import "@dashkite/altair/install"

globalThis.navigator ?= onLine: true

import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"


import Server from "./server"
import scenarios from "./scenarios"

import { scheme, domain, port } from "./configuration"

do ->

  # await Server.start port
  await Server.start port
  
  try
    print await test "Altair",
      for name, tests of scenarios { scheme, domain, port }
        test name, tests

  catch error
    throw error

  finally
    await Server.stop()
