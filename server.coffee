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
    errored = false
    req.on 'error', (e) ->
      res.send 404
      console.log 'error', e
      errored = true
    req.on 'end', ->
      if errored
        console.log 'error, so no analysis'
        return
      console.log 'analyzing', path
      analyzer = child.spawn "#{process.cwd()}/server-analyze.sh", [path], 'inherit'
      analyzer.stdout.pipe res
      analyzer.on 'exit', (code) ->
        console.log 'done', code


app.use express.static(
  if debug
    "#{process.cwd()}/client"
  else
    "#{process.cwd()}/client/build"
)

app.listen if debug then 8080 else (process.env.PORT || 3000)
