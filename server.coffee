debug = process.argv.length > 2

express = require 'express'
tmp = require 'tmp'
fs = require 'fs'
child = require 'child_process'
tmp.setGracefulCleanup()

app = express()

app.post '/analyze', (req, res) ->
  data = null
  tmp.file (err, path, fd) ->
    upload = fs.createWriteStream path
    req.pipe upload

    req.on 'end', ->
      console.log 'analyzing', path
      analyzer = child.spawn "#{process.cwd()}/server-analyze.sh", [path], {stdio: 'pipe'}
      analyzer.stdout.pipe res


app.use express.static(
  if debug
    "#{process.cwd()}/client"
  else
    "#{process.cwd()}/client/build"
)

app.listen if debug then 8080 else 80
