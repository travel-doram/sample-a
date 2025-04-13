var http = require('http');

http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.write("#### Request Headers####<br>")
  for (const key in req.headers) {
    res.write(`${key}: ${req.headers[key]}<br>`);
  }  


  res.write("<P>#### ENVIRONMENT Values####<br>")

  res.write(`TESTING_ENV: ${process.env.TESTING_ENV}<BR>`)
  res.write(`ENV_SET_PER_ENVIRONMENT: ${process.env.ENV_SET_PER_ENVIRONMENT}<BR>`)
  res.write(`ENV_SET_IN_YAML: ${process.env.ENV_SET_IN_YAML}<BR>`)
  res.write(`ENV_FROM_SECRET_MANAGER: ${process.env.ENV_FROM_SECRET_MANAGER}<BR>`)

  res.end('<P>Hello World!');
}).listen(3000);