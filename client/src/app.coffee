"use strict"
`define(['three'], function(three){return function(){`
overlayText = (document.getElementsByClassName 'overlayText')[0]
renderElement = (document.getElementsByClassName 'render')[0]

cancelClick = ->
  if document.onclick?
    document.onclick = null

latency = 0
xspread = 32
yspread = 40

soundfile = '/she.mp3'
chofile = '/she.cho'

audio = new (window.AudioContext ? window.webkitAudioContext)()
anaReq = null

setupGL = (c) ->
  renderer = new three.WebGLRenderer()
  camera = new three.PerspectiveCamera 15, c.width/c.height, .1, 200
  scene = new three.Scene()
  scene.camera = camera
  camera.position.z = 100
  camera.position.y = 20
  camera.lookAt new three.Vector3 0,0,0
  renderer.setSize c.width, c.height
  renderer.setClearColor 0x000000, 1

  renderElement.appendChild renderer.domElement

  light = new three.PointLight 0xFFFFFF
  light.position.x = 10
  light.position.y = 50
  light.position.z = 130
  light.intensity = 0
  scene.add light

  stage = new three.Mesh (new three.PlaneGeometry 2 * xspread, 2*yspread),
    new three.MeshLambertMaterial {color: new three.Color 0xFFFFFF}
  stage.rotation.x = -Math.PI / 2
  stage.position.y = -5
  scene.add stage

  return {renderer, scene, camera, light}

songStart = null
performance = null

loader = new three.JSONLoader
loader.load '/models/stick2.js', (geometry, materials) ->
  three.AnimationHandler.add anim for anim in geometry.animations
  makeDude = (colorHex, pos) ->
    newSurf = new three.MeshLambertMaterial {color: new three.Color colorHex}
    newSurf.skinning = true
    dude = new three.SkinnedMesh geometry, (new three.MeshFaceMaterial [newSurf])
    dude.position.x = pos.x
    dude.position.z = pos.y
    return dude

  playAnimation = (anim, offset, obj, tempo) ->
    obj.animation?.stop()
    obj.animation = new three.Animation obj, anim
    obj.animation.timeScale = tempo / 120
    obj.animation.currentTime += offset * 0.5 * tempo / 120
    obj.animation.play()
  performance = null

  gl = setupGL({width:1000, height:500})

  class DancePerformance
    danceMoves: ['gangnam style', 'creepy crab', 'two step', 'Wave']
    constructor: (data, @src) ->
      @songStart = audio.currentTime + .1
      @src.start @songStart

      @gl = gl

      @data = JSON.parse data
      @actors = {}
      for target, pos of @data['starting_positions']
        @actors[target] = makeDude (Math.random() * 0xffffff),
            {x: pos[0] * xspread, y: pos[1] * yspread}
        @gl.scene.add @actors[target]

      {@dance, @tempo} = @data
      @render()
    perform: (datum) ->
      vec = null
      for target in datum.target
        unless @actors[target]?
          @actors[target] = makeDude (Math.random() * 0xffffff),
            {x: Math.random() * xspread * 2 - xspread, y: 0}
          @gl.scene.add @actors[target]
        if datum.moveto?
          unless vec?
          	vec =
              x: (datum.moveto.x * xspread - @actors[target].position.x)
              y: (datum.moveto.y * yspread - @actors[target].position.z)
          @actors[target].target =
            x: vec.x + @actors[target].position.x
            y: vec.y + @actors[target].position.z
          @actors[target].speed = 0.4 * xspread #datum.speed * xspread
        anim = datum.action % @danceMoves.length
        playAnimation @danceMoves[anim], Math.floor(datum.action / @danceMoves.length), @actors[target], @tempo
    performUntil: (time) ->
      while @dance.length and @dance[0].time < time
        @perform @dance.shift()
    doLights: (time)->
      fadeIn = (time - @data['light_fade_in_start']) / (@data['light_fade_in_end'] - @data['light_fade_in_start'])
      fadeOut = (time - @data['light_fade_out_start']) / (@data['light_fade_out_end'] - @data['light_fade_out_start'])
      if fadeOut > 0
        @gl.light.intensity = Math.max((1 - fadeOut), 0)
        return
      if fadeIn < 1
        @gl.light.intensity = Math.min(fadeIn, 1)
        return
      @gl.light.intensity = 1
    update: (time, delta) ->
      @doLights time
      @performUntil time
      # do positions
      for key, actor of @actors when actor.target?
        r = actor.speed * delta
        dx = actor.target.x - actor.position.x
        dy = actor.target.y - actor.position.z
        distToTarget = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
        if r > distToTarget
          delete actor.target
          continue
        else
          actor.position.x += dx * r / distToTarget
          actor.position.z += dy * r / distToTarget
    lastRender: null
    render: ->
      return if @dead
      r = audio.currentTime
      if @lastRender?
        dr = r - @lastRender
        three.AnimationHandler.update dr
      @lastRender = r
      songTime = audio.currentTime - @songStart - latency
      @update songTime, dr if dr?

      @gl.renderer.render @gl.scene, @gl.camera
      requestAnimationFrame (=> @render())
    remove: ->
      for key, actor of @actors
        if actor.animation?
          actor.animation.stop()
          three.AnimationHandler.removeFromUpdate actor.animation
        @gl.scene.remove actor
      @src.stop(0)
      @dead = true

  hover = (e) ->
    e.stopPropagation()
    e.preventDefault()
  document.ondragover = document.ondragleave = hover
  document.ondrop = (e) ->
    cancelClick()
    if anaReq?
      anaReq.abort()
      anaReq = null
      
    overlayText.textContent = 'Decoding audio file..'
    hover e
    reader = new window.FileReader()
    reader.onload = -> audio.decodeAudioData reader.result, (buff) ->
      overlayText.textContent = 'Creating choreography (this will take a few minutes)...'
      src = audio.createBufferSource()
      src.buffer = buff
      src.connect audio.destination

      # okay, we got a buffer, now we have to analyze it!
      anaReq = new XMLHttpRequest()
      anaReq.open "POST", "/analyze", true
      anaReq.responseType = 'json'
      anaReq.onload = ->
        overlayText.textContent = 'Choreography complete! Click to play!'
        document.onclick = ->
          overlayText.textContent = ''
          performance?.remove()
          performance = new DancePerformance anaReq.response, src
          anaReq = null
          cancelClick()
      anaReq.onerror = ->
        overlayText.textContent = 'Oops! Choreography failed! Try Again!'
      anaReq.send reader.result
      delete reader.onload
    reader.readAsArrayBuffer e.dataTransfer.files[0]

  req = new XMLHttpRequest()
  req.open 'GET', soundfile, true
  req.responseType = 'arraybuffer'

  req.send()
  req.onload = ->
    audio.decodeAudioData req.response, (buff) ->
      danceReq = new XMLHttpRequest()
      danceReq.open 'GET', chofile, true

      danceReq.send()
      danceReq.onload = ->
        overlayText.textContent = 'Click to Play Demo, or Drag your own file in!'
        document.onclick = ->
          overlayText.textContent = ''

          src = audio.createBufferSource()
          src.buffer = buff
          src.connect audio.destination

          # start in 100ms!
          performance?.remove()
          performance = new DancePerformance danceReq.response, src
          cancelClick()
`};});`