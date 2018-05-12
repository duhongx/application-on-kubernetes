FROM node:8
MAINTAINER Du Hong <duhongxxx@gmail.com>
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \ 
    echo 'Asia/Shanghai' >/etc/timezone && \
    echo "export LC_ALL=en_US.UTF-8" >> /etc/profile && \
    . /etc/profile 
ENV REFRESHED_AT 2018-05-12
