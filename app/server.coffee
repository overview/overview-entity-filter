app = require('./app')

port = process.env.PORT || 3000

server = app.listen port, ->
  addr = server.address()

  console.log("Listening at http://%s:%d", addr.address, addr.port)
