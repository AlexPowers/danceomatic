"use strict"
`define(['three'], function(three){return function(){`

audio = new (window.AudioContext ? window.webkitAudioContext)()
req = new XMLHttpRequest()
req.open 'GET', '/kafziel.wav', true
req.responseType = 'arraybuffer'

setupGL = (c) ->
  renderer = new three.WebGLRenderer()
  camera = new three.PerspectiveCamera 45, c.width/c.height, 0.1, 100
  scene = new three.Scene()
  scene.camera = camera
  camera.position.z = 10
  renderer.setSize c.width, c.height
  renderer.setClearColor 0x000000, 1

  document.body.appendChild renderer.domElement

  pointLight = new three.PointLight 0xFFFFFF
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130
  scene.add pointLight

  return {renderer, scene, camera}


loader = new three.JSONLoader
loader.load '/models/stick2.js', (geometry, materials) ->
  makeSphere = ->
    sphere = new three.SkinnedMesh geometry,
      (new three.MeshFaceMaterial materials)
    mat.skinning = true for mat in materials
    three.AnimationHandler.add anim for anim in geometry.animations
    return sphere

  sphere = makeSphere()

  gl = setupGL({width:500, height:500})
  animation = new three.Animation(
    sphere, 'ArmatureAction'
    )

  gl.scene.add sphere

  render = ->
    three.AnimationHandler.update .01
    # console.log animation
    gl.renderer.render gl.scene, gl.camera
    # gl.renderer.render gl.scene, gl.camera
    requestAnimationFrame render
  render()
  req.send()
  req.onload = ->
    success = (buff) -> setTimeout (->
      src = audio.createBufferSource()
      src.buffer = buff
      src.connect audio.destination
      animation.play()
      ), 5000
      # src.start 0

    audio.decodeAudioData req.response, success


`};});`