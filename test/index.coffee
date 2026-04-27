# set up fetch API
import "@dashkite/altair/install"

globalThis.navigator ?= onLine: true

import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"


import { start, stop } from "./server"
import scenarios from "./scenarios"
import offline from "./scenarios/offline"

import { scheme, domain, port } from "./configuration"

context = { 
  scheme
  domain
  port
  origin: "#{ scheme }://#{ domain }:#{ port }"
  start
  stop
}

do ->

  print await test "Altair", await do ->

    { parallel, sequential } = await scenarios()

    results = []

    try

      await start port

      for name, runner of parallel
        results.push test name, runner context

      await Promise.all results

      for name, runner of sequential
        results.push await test name, runner context

    catch error
      throw error

    finally
      await stop()

    results

