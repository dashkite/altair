export default ->
  parallel:
    "core methods": ( await import( "./core-methods" ) ).default
    "error-handling": ( await import( "./error-handling" ) ).default
    "concurrency": ( await import( "./concurrency" ) ).default
    "unauthorized": ( await import( "./unauthorized" ) ).default
    "retries": ( await import( "./retries" ) ).default
    "caching": ( await import( "./caching" ) ).default
    "sublime errors": ( await import( "./sublime-errors" ) ).default
  sequential: {}
