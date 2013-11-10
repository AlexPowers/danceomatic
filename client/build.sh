#!/bin/bash
r.js -o app.build.js
rm build/src/*.coffee
rm build/src/build.*
rm build/src/coffee-script.js
rm build/src/cs.js
cp -r style Choreographer models build
cp *.html build
