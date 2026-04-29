import "./core-methods"
import "./error-handling"
import "./concurrency"
import "./unauthorized"
import "./retries"
import "./caching"
import "./sublime-errors"
import "./offline"

load = ( names ) ->
  results = {}
  for name in names
    path = "./#{ name }"
    results[ name ] = ( await import( path )).default
  results

export default ->
  parallel: await load [
    "core-methods"
    "error-handling"
    "concurrency"
    "unauthorized"
    "retries"
    "caching"
    "sublime-errors"
  ]
  sequential: await load [
    "offline"
  ]
