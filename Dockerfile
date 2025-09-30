# Runtime NGINX sobre UBI9 (no S2I)
FROM registry.access.redhat.com/ubi9/nginx-120

# Tu sitio queda en /opt/app-root/src
COPY . /opt/app-root/src

# Config explícita para puerto 8080 y /healthz
COPY openshift/nginx/nginx-default.conf /etc/nginx/conf.d/default.conf

# Permisos para ejecutar con UID arbitrario (SCC restricted)
RUN chgrp -R 0 /etc/nginx /var/log/nginx /var/cache/nginx /opt/app-root/src \
 && chmod -R g=u /etc/nginx /var/log/nginx /var/cache/nginx /opt/app-root/src

EXPOSE 8080
USER 1001
# Arranca NGINX en primer plano (evita el "usage" de la imagen S2I)
CMD ["nginx", "-g", "daemon off;"]
