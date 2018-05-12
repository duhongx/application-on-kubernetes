FROM 192.168.131.223/k8s/java:8
MAINTAINER Du Hong <duhongxxx@gmail.com>
COPY qgsp-manager.jar /opt/qgsp-manager.jar
EXPOSE 8080
COPY app.sh /opt/app.sh
RUN chmod +x /opt/app.sh
ENTRYPOINT ["/opt/app.sh"]
