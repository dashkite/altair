import * as Type from "@dashkite/joy/type"
import { Machine, Async, $end } from "@dashkite/talos"
import APIDescription from "./api-description"
import Core from "./vega-core"


# TODO: Should this be moved to some sort of generic type dispatching?
hasResource = ( talos ) ->
  { resource } = talos.context
  ( Type.isObject resource ) && resource.origin? && resource.name?


When = 
  hasAPIDescription: ( talos ) ->
    talos.context.resource.api?


Run =
  parseResource: ( talos ) ->
    if hasResource talos
      { resource, content } = talos.context
      resource.bindings ?= {}
      if resource.content? && !content?
        talos.context.content = resource.content
    else
      throw new Error "unable to parse resource"

  fetchAPIDescription: ( talos ) ->
    for await current from APIDescription.start talos.context.resource
      yield current
    if current.failure
      throw current.error
    talos.context.resource.api = current.context.json 

  readySky: ( talos ) ->
    { resource, content, method } = talos.context
    talos.context.sky = { resource..., content, method }
       
  run: ( talos ) ->
    for await current from Core.request talos.context.sky
      yield current
    if current.failure
      throw current.error
    talos.context.sublime = current.context.sublime
    

machine = Machine.make "vega-client: issue",
  start: "parseResource"
  parseResource:
    run: Run.parseResource
    move: "fetchAPIDescription"
  fetchAPIDescription:
    skip:
      when: When.hasAPIDescription
      move: "readySky"
    default:
      run: Run.fetchAPIDescription
      move: "readySky" 
  readySky:
    run: Run.readySky
    move: "run"
  run:
    run: Run.run
    move: $end


Issue =
  start: ( context ) -> Async.start machine, context


export default Issue