# set up fetch API
import "@dashkite/altair/install"

import { setGlobalDispatcher, Agent } from "undici"

setGlobalDispatcher new Agent
  connectTimeout: 500
  keepAliveTimeout: 100
  keepAliveMaxTimeout: 500

globalThis.navigator ?= onLine: true

import { test } from "@dashkite/amen"

import scenarios from "./scenarios"
import Server from "./server"

start = -> 
  globalThis.navigator.onLine = true
  Server.start [ "api" ]

stop = -> 
  globalThis.navigator.onLine = false
  Server.stop [ "api" ]

export default ( context ) ->

  { parallel, sequential } = await scenarios()

  results = []

  try

    await Server.start [ "api" ]

    for name, scenario of parallel
      results.push test name, scenario context

    # wait for the all parallel tests to finish
    await Promise.all results

    for name, scenario of sequential
      results.push await test name, 
        await scenario { context..., start, stop }

  catch error
    throw error

  finally
    await Server.stop [ "api" ]

  results
  
