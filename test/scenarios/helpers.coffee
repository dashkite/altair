import assert from "@dashkite/assert"
import { tap, start, resolve, map } from "@dashkite/river"
import { test } from "@dashkite/amen"
import { curry, binary } from "@dashkite/joy/function"
import { isReactor } from "@dashkite/joy/type"
import Generic from "@dashkite/generic"
import sky from "@dashkite/sky-sublime"
import Sublime from "@dashkite/sublime"
import Altair from "@dashkite/altair"
import Events from "./events"


Address =
  make: ->
    Math
      .random()
      .toString 36
      .slice 2

trace = tap ( event ) ->
  console.log { event }

HTTP = Altair
  .make()
  .use Sublime.make [ sky ]

subtest = ( description, action ) ->
  test description, wait: 1000, action

advance = curry binary do ->

  Generic.make 
      name: "advance"
      default: ( args... ) ->
        console.log args

    .define [ isReactor, Object ], ( events, options ) ->

      options = { throw: true, options... }
      { done, value } = await events.next options.next

      if value?.error? && options.throw
        # consume the rest of the events so we don't hang
        start events
        throw value.error
  
      assert.equal options.name, value.name if options.name?
      assert.equal options.scope, value.scope if options.scope?
      assert.equal options.done, done if options.done?

      { done, value }

    .define [ isReactor, String ], ( reactor, name ) ->
      advance reactor, Events[ name ]

    .define [ isReactor, Array ], ( events, options ) ->
      # TODO map should not pass an index (add mapIndexed?)
      f = ( options, i ) -> advance events, options
      start resolve map f, options
        

export { 
  Address
  trace
  HTTP
  subtest
  advance
}
