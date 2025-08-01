# TODO process returned credentials
# TODO 401 response handling
# TODO how to set up next iteration for negotiation

finalize = ( context ) ->
  yield name: "finalize"
  context

export default finalize