debug = process.argv.length > 2

express = require 'express'

app = express()

app.use express.static(
  if debug
    "#{process.cwd()}/client"
  else
    "#{process.cwd()}/client/build"
)

app.listen if debug then 8080 else 69
