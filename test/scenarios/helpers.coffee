import { tap, start } from "@dashkite/river"
import { test } from "@dashkite/amen"
import sky from "@dashkite/sky-sublime"
import Sublime from "@dashkite/sublime"
import Altair from "@dashkite/altair"

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

advance = ( events, options = { throw: true }) ->
  { done, value } = await events.next options.next
  if value?.error? && options.throw
    # consume the rest of the events so we don't hang
    start events
    throw value.error
  { done, value }

export { 
  Address
  trace
  HTTP
  subtest
  advance
}
