import { test } from "@dashkite/amen"
import scenarios from "./scenarios"
import configuration from "./configuration"
{ scheme, domain, port } = configuration

cat = ( ax, bx ) -> [ ax..., bx... ]

do ->

  origin = "#{ scheme }://#{ domain }:#{ port }"
  context = { scheme, domain, port, origin }
  
  { parallel, sequential } = await scenarios()

  window.test =
    results: []
    parallel:
      run: ->

        results = []
        for name, runner of parallel
          results.push test name, runner context

        # wait for all the tests to finish and save the result
        window.test.results = 
          cat window.test.results, 
            await Promise.all results

    sequential:
      run: ->
        test "Altair (Browser: Sequential)",
          for name, runner of sequential
            window.test.results.push await test name, runner context
