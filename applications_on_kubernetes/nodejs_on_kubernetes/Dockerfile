FROM 192.168.131.223/k8s/node:8
MAINTAINER Du Hong <duhongxxx@gmail.com>
WORKDIR /data
COPY  target/ /data/
EXPOSE 4889
ENTRYPOINT ["node", "server.js", "4889"]
