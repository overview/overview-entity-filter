FROM node:0.12.7

MAINTAINER Adam Hooper <adam@adamhooper.com>

RUN groupadd -r app && useradd -r -g app app

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
COPY package.json /tmp/package.json
RUN cd /tmp && npm install --production
RUN mkdir -p /opt/app && cp -a /tmp/node_modules /opt/app/

# From here we load our application's code in, therefore the previous docker
# "layer" thats been cached will be used if possible
COPY gulpfile.* LICENSE README.md server.js /opt/app/
COPY app /opt/app/app/
COPY css /opt/app/css/
COPY data /opt/app/data/
COPY js /opt/app/js/
COPY lib /opt/app/lib/
COPY views /opt/app/views/

RUN cd /opt/app && node_modules/.bin/gulp

USER app
WORKDIR /opt/app

ENV PORT 3001
EXPOSE 3001
CMD [ "node", "server.js" ]
