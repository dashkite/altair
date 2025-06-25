viable = ( context ) ->
  if !( context.viable == false )
    context.viable = false
    true
  else
    false

export default viable