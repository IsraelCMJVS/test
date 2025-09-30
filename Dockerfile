# Runtime NGINX sobre UBI9 (no S2I)
FROM registry.access.redhat.com/ubi9/nginx-120

# Copiamos el sitio/app
COPY . /opt/app-root/src

# Config explícita (puerto 8080 + /healthz)
COPY openshift/nginx/nginx-default.conf /etc/nginx/conf.d/default.conf

# No intentes chgrp/chown sobre /etc; en build rootless falla.
# Para OCP no necesitamos escribir en /etc ni en /opt/app-root/src.
# Los logs van a stdout/stderr y NGINX ya está preparado para UID arbitrario.

EXPOSE 8080
USER 1001
CMD ["nginx", "-g", "daemon off;"]
