const http = require("http");
const fs = require("fs");
const os = require("os");
const ip = require('ip');

http.createServer((req, res) => {
  if (req.url === "/") {
      fs.readFile("./public/index.html", "UTF-8", (err, body) => {
      res.writeHead(200, {"Content-Type": "text/html"});
      res.end(body);
    });
  } else if(req.url.match("/sysinfo")) {
    myHostName=os.hostname();
    myTotalMem=(os.totalmem() / 1000000);
    FREEMEM=(os.freemem() / 1000000);
    uptime=(os.uptime());
    var days = Math.trunc((uptime / (3600*24 )));
    var hours = Math.trunc((uptime % (3600*24) / 3600));
    var minutes = Math.trunc((uptime % 3600 / 60));
    var seconds = Math.trunc((uptime % 60));
    cpuarray = os.cpus();
    html=`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Node JS Response</title>
      </head>
      <body>
        <p>Hostname: ${myHostName}</p>
        <p>IP: ${ip.address()}</p>
        <p>Server Uptime: ${"Days: " + days + ", " + "Hours: " + hours + ", " + "Minutes: " + minutes + ", " + "Seconds: " + seconds}</p>
        <p>Total Memory: ${myTotalMem.toFixed(3) + " MB"} </p>
        <p>Free Memory: ${FREEMEM.toFixed(3) + " MB"} </p>
        <p>Number of CPUs: ${cpuarray.length} </p>
      </body>
    </html>`
    res.writeHead(200, {"Content-Type": "text/html"});
    res.end(html);
  } else {
    res.writeHead(404, {"Content-Type": "text/plain"});
    res.end(`404 File Not Found at ${req.url}`);
  }
}).listen(3000);

console.log("Server listening on port 3000");