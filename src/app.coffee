"use strict"
`define(['three', 'underscore'], function(three, _){return function(){`

audio = new (window.AudioContext ? window.webkitAudioContext)()
req = new XMLHttpRequest()
req.open 'GET', '/kafziel.wav', true
req.responseType = 'arraybuffer'

setupGL = (c) ->
  renderer = new three.WebGLRenderer()
  camera = new three.PerspectiveCamera 45, c.width/c.height, 0.1, 1000
  scene = new three.Scene()
  scene.camera = camera
  camera.position.z = 100
  camera.position.y = 10
  renderer.setSize c.width, c.height
  renderer.setClearColor 0x000000, 1

  document.body.appendChild renderer.domElement

  pointLight = new three.PointLight 0xFFFFFF
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130
  scene.add pointLight

  return {renderer, scene, camera}

tempo = 100

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

  gl = setupGL({width:500, height:500})

  sphere = makeDude 0xff00ff, {x: 10, y: 10}
  gl.scene.add sphere
  cube = makeDude 0x00ff00, {x:-10, y:10}
  gl.scene.add cube

  playAnimation = (anim, obj) ->
    if obj.animation?
      obj.animation.stop()
    obj.animation = new three.Animation obj, anim
    obj.animation.timeScale = tempo / 120
    obj.animation.play()

  # console.log animation.timeScale
  # animation.timeScale = 12
  lastRender = null
  render = ->
    r = audio.currentTime
    if lastRender?
      three.AnimationHandler.update r - lastRender
    lastRender = r
    gl.renderer.render gl.scene, gl.camera
    requestAnimationFrame render
  render()
  req.send()
  req.onload = ->
    success = (buff) ->
      src = audio.createBufferSource()
      src.buffer = buff
      src.connect audio.destination
      setTimeout (->
        playAnimation 'Super Wave', sphere
        ), 1000
      # src.start 0

    audio.decodeAudioData req.response, success


`};});`