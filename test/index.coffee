import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import print from "@dashkite/amen-console"
import chalk from "chalk"
import puppeteer from "puppeteer"
import express from "express"
import Atlas from "@dashkite/atlas"
import SkyPreset from "@dashkite/atlas/presets/sky"

import configuration from "./configuration"

import Path from "node:path"

# configure the import map generator preset
SkyPreset.apply
  provider: "jsdelivr"
  build: "build/browser"
  origin: configuration.provider

# set up simple local server so we can establish a base URL
# for resolving relative paths
express()
  .use express.static "build/browser", redirect: false
  .listen 3000

do ->

  # generate the import map
  map = await Atlas.generate [ 
    # "./build/browser/src/index.js" 
    "./build/browser/test/client/index.js"
  ]

  # launch the headless browser
  browser = await puppeteer.launch()
  page = await browser.newPage()

  # set up error handlers
  page.on "error", ( error ) -> 
    console.error error 

  page.on "pageerror", ( error ) -> 
    console.error error 
  
  # allow logging to the console
  page.on "console", ( message ) ->
    type = message.type()
    console[ type ] ( chalk.blue.dim " browser ▷" ), 
      switch type
        when "warning" then chalk.amber message.text()
        when "error" then chalk.red message.text()
        else chalk.green message.text()

  console.log ""
  # navigate to our shell page
  await page.goto "http://localhost:3000/test/client/temp.html"

  # add the import map
  await page.addScriptTag
    content: JSON.stringify map
    type: "importmap"

  # add the tests as a script
  await page.addScriptTag 
    path: "build/browser/test/client/index.js"
    type: "module"

  # make sure the tests are ready to run
  await page.waitForFunction -> window.__test?

  # at last! we can run the tests
  results = await page.evaluate -> window.__test()

  # print the rest results to the console
  console.log ""
  print results
  
  process.exit if success then 0 else 1
