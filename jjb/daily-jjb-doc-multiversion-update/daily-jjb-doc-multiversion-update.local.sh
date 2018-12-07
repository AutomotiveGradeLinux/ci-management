#!/bin/bash

set -e

# make sure 'node' is in path (debian calls it nodejs)
mkdir -p bin
ln -sf /usr/bin/nodejs bin/node
export PATH=$PATH:`pwd`/bin

[[ -z "$WORKSPACE" ]] && WORKSPACE=$(pwd -P)
HTDOCS=${HTDOCS:-$WORKSPACE/htdocs}

. include-doc-multiversion-update.sh

( sleep 7 ; firefox http://127.0.0.1:8000 ) &

cd $HTDOCS

node <<EOF
// from https://gist.github.com/ryanflorence/701407
["http","url","path","fs"].forEach(m => {global[m] = require(m);} );
var port=process.argv[2] || 8000;

http.createServer(function(request, response) {
  var uri=url.parse(request.url).pathname;
  var filename=path.join(process.cwd(), uri);
  fs.exists(filename,function(exists) {
    if(!exists) {
      response.writeHead(404, {"Content-Type": "text/plain"});
      response.write("404 Not Found\n");
      response.end();
      return;
    }
    if (fs.statSync(filename).isDirectory()) filename+='/index.html';
    fs.readFile(filename,"binary",function(err, file) {
      if(err) {
        response.writeHead(500,{"Content-Type": "text/plain"});
        response.write(err+"\n");
        response.end();
        return;
      }
      response.writeHead(200);
      response.write(file,"binary");
      response.end();
    });
  });
}).listen(parseInt(port,10));
console.log("Static file server running at\n  => http://localhost:" + port + "/\nCTRL + C to shutdown");
EOF

