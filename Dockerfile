# create intermediate imgae
FROM node:12 as BUILD_IMAGE

# install curl and bash
RUN apk update && apk add curl bash && rm -rf /var/cache/apk/*

# install node-prune (https://github.com/tj/node-prune)
RUN curl -sfL https://install.goreleaser.com/github.com/tj/node-prune.sh | bash -s -- -b /usr/local/bin

# Create app directory
WORKDIR /app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

# install node dependencies
RUN npm install

# copy project
COPY . .

RUN npm config set unsafe-perm true

# build nest app
RUN npm run build
# remove dev dependencies
RUN npm prune --production
# remove .map, readme and other not needed files with node-prune
RUN /usr/local/bin/node-prune

# create image from intermediate build_image including only necessary files
FROM node:12

# Create app directory
WORKDIR /app

# copy necessary files
COPY --from=BUILD_IMAGE /app/dist ./dist
COPY --from=BUILD_IMAGE /app/node_modules ./node_modules

USER node
ENV PORT=8080
# expose app port
EXPOSE 8080

# start app
ENTRYPOINT [ "node", "./dist/main.js" ]
