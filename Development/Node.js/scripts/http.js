const http = require('http');
const os = require('os');
console.log("Kubi a server starting ... ");

var handler = function(request, response) {
    console.log("Recei ved request from" + request.connection.remoteAddress);
    response.writeHead(200);
    response.end("You've hit " + os.hostname() + "\n");
}

var www = http.createServer(handler);
www.listen(9999);
