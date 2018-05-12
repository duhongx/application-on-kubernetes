#!/bin/bash
java -Dspring.profiles.active=prod -jar -Xms2048m -Xmx4096m -Dlogs.dir=/opt/logs /opt/qgsp-manager.jar
