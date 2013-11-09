"use strict"
`define(['three'], function(three){return function(){`

audio = new (window.AudioContext ? window.webkitAudioContext)()
req = new XMLHttpRequest()
req.open 'GET', '/kafziel.wav', true
req.responseType = 'arraybuffer'

setupGL = (c) ->
  renderer = new three.WebGLRenderer()
  camera = new three.PerspectiveCamera 45, c.width/c.height, 0.1, 100t
  scene = new three.Scene()
  scene.camera = camera
  camera.position.z = 10
  renderer.setSize c.width, c.height
  renderer.setClearColorHex 0x000000, 1

  document.body.appendChild renderer.domElement

  pointLight = new three.PointLight 0xFFFFFF
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130
  scene.add pointLight

  return {renderer, scene, camera}


loader = new three.JSONLoader
loader.load '/models/stick.js', (geometry) ->
  makeSphere = ->
    sphere = new three.Mesh geometry,
      (new three.MeshLambertMaterial color:0xCC0000)

    return sphere
  sphere = makeSphere()

  gl = setupGL({width:500, height:500})

  gl.scene.add sphere
  drawBuffer = (gl, b) ->
    gl.bindBuffer gl.ARRAY_BUFFER, b
    gl.vertexAttribPointer gl.vertexPos, b.n, gl.FLOAT, false, 0, 0
    gl.drawArrays gl.TRIANGLES, 0, b.n

  gl.renderer.render(gl.scene, gl.camera)

req.onload = ->
  success = (buff) ->
    src = audio.createBufferSource()
    src.buffer = buff
    src.connect audio.destination
    src.start 0

  audio.decodeAudioData req.response, success

req.send()

`};});`