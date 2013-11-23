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
      tmp.file (err, path2, fd2) ->
        analysis = fs.createWriteStream path2
        console.log 'analyzing', path, ' to ', path2
        analyzer = child.spawn "#{process.cwd()}/server-analyze.sh", [path], 'inherit'
        analyzer.stdout.pipe analysis
        analyzer.on 'exit', (code) ->
          fs.unlink path
          console.log 'done', code
          if code isnt 0
            res.send 500
            fs.unlink path2
            return

          res.statusCode = 200
          analysis = fs.createReadStream path2
          analysis.pipe res
          analysis.on 'end', -> fs.unlink path2


app.use express.static(
  if debug
    "#{process.cwd()}/client"
  else
    "#{process.cwd()}/client/build"
)

app.listen if debug then 8080 else (process.env.PORT || 3000)
