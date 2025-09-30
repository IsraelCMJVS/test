FROM registry.access.redhat.com/ubi9/nginx-120

# Copiamos el sitio
COPY . /opt/app-root/src

# Sobrescribe la config principal (en vez de conf.d)
COPY openshift/nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
USER 1001
CMD ["nginx", "-g", "daemon off;"]
