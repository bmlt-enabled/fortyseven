FROM node:8.9.3-alpine

ADD ./package.json /opt/package.json
WORKDIR /opt
RUN npm install
ADD . /opt

CMD source process.env && bin/hubot --alias $HUBOT_NAME --name $HUBOT_NAME --adapter $ADAPTER
EXPOSE 8080
