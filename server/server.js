const app = require('./app');

const port = process.env.PORT || 3000;

const server = app.listen(port, function() {
  const addr = server.address();
  console.log("Listening at http://%s:%d", addr.address, addr.port);
});
