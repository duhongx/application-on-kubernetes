FROM docker.elastic.co/elasticsearch/elasticsearch-oss:6.3.2
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone
RUN cd /usr/share/elasticsearch && ./bin/elasticsearch-plugin install -b https://github.com/medcl/elasticsearch-analysis-ik/relea
ses/download/v6.3.2/elasticsearch-analysis-ik-6.3.2.zip
