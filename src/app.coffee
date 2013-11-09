"use strict"
`define(['gl-matrix'], function(mat){return function(){`
{mat4} = mat

audio = new (window.AudioContext ? window.webkitAudioContext)()
req = new XMLHttpRequest()
req.open 'GET', '/kafziel.wav', true
req.responseType = 'arraybuffer'

setupGL = (c) ->
  gl = c.getContext 'experimental-webgl'

  makeShader = (tag, src) ->
    t = gl.createShader tag
    gl.shaderSource t, src
    gl.compileShader t
    return t
  frag = makeShader gl.FRAGMENT_SHADER, '''
  precision mediump float;
  void main(void) {
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
  }
  '''
  vert = makeShader gl.VERTEX_SHADER, '''
  attribute vec3 aVertexPosition;

  uniform mat4 uMVMatrix;
  uniform mat4 uPMatrix;

  void main(void) {
    gl_Position = vec4(aVertexPosition, 1.0);
  }
  '''
#uPMatrix * uMVMatrix * 
  prog = gl.createProgram()
  gl.attachShader prog, vert
  gl.attachShader prog, frag
  gl.linkProgram prog
  gl.useProgram prog

  gl.vertexPos = gl.getAttribLocation prog, 'aVertexPosition'
  gl.pMatPos = gl.getUniformLocation prog, 'uPMatrix'
  gl.mvMatPos = gl.getUniformLocation prog, 'uMVMatrix'

  gl.p = mat4.create()
  gl.mv = mat4.create()

  [gl.viewportWidth, gl.viewportHeight] = [c.width, c.height]
  gl.viewport 0, 0, c.width, c.height

  gl.clearColor 0,0,0,1
  gl.enable gl.DEPTH_TEST
  gl.updateMats = ->
    gl.uniformMatrix4fv gl.pMatPos, false, gl.p
    gl.uniformMatrix4fv gl.mvMatPos, false, gl.mv

  return gl

makeStick = (gl) ->
  stick = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, stick
  verts = [100,100,0,
           0,0,0,
           200,0,0]
  gl.bufferData gl.ARRAY_BUFFER, new Float32Array(verts), gl.STATIC_DRAW
  stick.n = verts.length / 3
  return stick

drawBuffer = (gl, b) ->
  gl.bindBuffer gl.ARRAY_BUFFER, b
  gl.vertexAttribPointer gl.vertexPos, b.n, gl.FLOAT, false, 0, 0
  gl.drawArrays gl.TRIANGLES, 0, b.n

gl = setupGL document.getElementById 'canvas'

stick = makeStick(gl)

drawScene = ->
  gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT
  mat4.perspective 45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, gl.p
  mat4.identity gl.mv
  gl.updateMats()
  drawBuffer gl, stick

drawScene()

req.onload = ->
  success = (buff) ->
    src = audio.createBufferSource()
    src.buffer = buff
    src.connect audio.destination
    src.start 0

  audio.decodeAudioData req.response, success

req.send()

`};});`