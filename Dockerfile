# TODO might be better image to pull: https://hub.docker.com/r/markadams/chromium-xvfb
FROM node:23-alpine3.20

# Ensure ts-sample-a runs as non-root user
RUN addgroup -S ts-sample-a && adduser -S ts-sample-a -G ts-sample-a
WORKDIR /usr/src/app
RUN chown -Rf ts-sample-a:ts-sample-a /usr/src/app
COPY --chown=ts-sample-a package*.json /usr/src/app
RUN npm install
COPY --chown=ts-sample-a . .

USER ts-sample-a

CMD ["npm","run", "dev"]