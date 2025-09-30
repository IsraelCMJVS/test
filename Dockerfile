FROM registry.access.redhat.com/ubi9/nginx-120
COPY . /opt/app-root/src
EXPOSE 8080