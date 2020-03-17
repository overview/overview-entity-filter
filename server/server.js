/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const app = require('./app');

const port = process.env.PORT || 3000;

var server = app.listen(port, function() {
  const addr = server.address();

  return console.log("Listening at http://%s:%d", addr.address, addr.port);
});
