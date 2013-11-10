"use strict"
`define(['three', 'underscore'], function(three, _){return function(){`
latency = 0
xspread = 32
yspread = 40


audio = new (window.AudioContext ? window.webkitAudioContext)()
req = new XMLHttpRequest()
req.open 'GET', '/Choreographer/she.wav', true
req.responseType = 'arraybuffer'

setupGL = (c) ->
  renderer = new three.WebGLRenderer()
  camera = new three.PerspectiveCamera 30, c.width/c.height, .1, 200
  scene = new three.Scene()
  scene.camera = camera
  camera.position.z = 100
  camera.position.y = 20
  camera.lookAt new three.Vector3 0,0,0
  renderer.setSize c.width, c.height
  renderer.setClearColor 0x000000, 1

  document.body.appendChild renderer.domElement

  pointLight = new three.PointLight 0xFFFFFF
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130
  scene.add pointLight

  stage = new three.Mesh (new three.PlaneGeometry 2 * xspread, 2*yspread),
    new three.MeshLambertMaterial {color: new three.Color 0xFFFFFF}
  stage.rotation.x = -Math.PI / 2
  stage.position.y = -5
  scene.add stage

  return {renderer, scene, camera}

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

  gl = setupGL({width:1000, height:500})

  playAnimation = (anim, obj, tempo) ->
    if obj.animation?
      obj.animation.stop()
    obj.animation = new three.Animation obj, anim
    obj.animation.timeScale = tempo / 120
    obj.animation.play()

  class DancePerformance
    danceMoves: ['creepy crab', 'two step']
    constructor: (data) ->
      {@dance, @tempo} = JSON.parse data
      @actors = {}
    perform: (datum) ->
      for target in datum.target
        unless @actors[target]?
          @actors[target] = makeDude (Math.random() * 0xffffff),
            {x: Math.random() * xspread * 2 - xspread, y: Math.random() * yspread * 2 - yspread}
          gl.scene.add @actors[target]
        playAnimation @danceMoves[datum.action % @danceMoves.length], @actors[target], @tempo
    performUntil: (time) ->
      while @dance.length and @dance[0].time < time
        @perform @dance.shift()

  lastRender = null
  render = ->
    r = audio.currentTime
    if lastRender?
      three.AnimationHandler.update r - lastRender
    lastRender = r
    if performance? and songStart?
      songTime = audio.currentTime - songStart - latency
      performance.performUntil songTime if songTime > 0

    gl.renderer.render gl.scene, gl.camera
    requestAnimationFrame render
  render()
  req.send()
  req.onload = ->
    audio.decodeAudioData req.response, (buff) ->
      danceReq = new XMLHttpRequest()
      danceReq.open 'GET', '/Choreographer/she.cho', true
      danceReq.responseType = 'json'
      danceReq.send()
      danceReq.onload = ->
        performance = new DancePerformance danceReq.response
        src = audio.createBufferSource()
        src.buffer = buff
        src.connect audio.destination

        # start in 100ms!
        songStart = audio.currentTime + .1
        src.start songStart

`};});`