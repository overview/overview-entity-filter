require('./show.scss'); // compile styles

const $ = require('jquery');
const App = require('./App');

const { searchParams } = new URL(document.location);
const options = {
  server: searchParams.get('server'),
  origin: searchParams.get('origin'),
  documentSetId: searchParams.get('documentSetId'),
  apiToken: searchParams.get('apiToken')
};

const app = new App($('<div id="main"></div>').appendTo('body'), options)
  .render()
  .start();
