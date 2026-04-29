# IMPORTANT: We need to load the node test before anything
# else to ensure that global Fetch API is property installed
import node from "./node"
import mimic from "./mimic"

import express from "express"
import { test } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import Server from "./server"
import api from "./server/api"

import { scheme, domain, port } from "./configuration"

Server.add "api", { app: api, port }
Server.add "static", 
  app: express().use ( express.static "./build/browser" )
  port: port + 1

context = { 
  scheme, domain, port
  origin: "#{ scheme }://#{ domain }:#{ port }"
}

do ->
  print await test "Altair", [
    test "Node", await node context
    test "Browser", await mimic context
  ]

