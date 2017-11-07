FROM node:0.12.7

MAINTAINER Adam Hooper <adam@adamhooper.com>

RUN groupadd -r app && useradd -r -g app app

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
COPY package.json package-lock.json /opt/app/
RUN apt-get update \
      && apt-get -y install libicu-dev \
      && cd /opt/app \
      && npm install --production

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

ENV PORT 80
EXPOSE 80
WORKDIR /opt/app
CMD /usr/local/bin/node /opt/app/server.js
