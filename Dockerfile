FROM alpine:3

LABEL maintainer="Ranielly Ferreira <eu@raniellyferreira.com.br>"

ENV NGINX_VERSION 1.17.10
ENV OPENRESTY_VERSION 1.15.8.3
ENV NGX_DEVEL_KIT_VERSION 0.3.1
ENV NGINX_LUA_MODULE_VERSION 0.10.15

RUN set -x \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update --no-cache \
    && apk upgrade --no-cache

RUN set -x \
    && apk add --no-cache --virtual .build-deps \
    tzdata \
    ca-certificates \
    libressl \
    pcre \
    zlib \
    build-base \
    linux-headers \
    libressl-dev \
    pcre-dev \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    zlib-dev \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    libedit-dev \
    bash

WORKDIR /tmp

RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

ADD http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /tmp
ADD https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz /tmp
ADD https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz /tmp/nginx_devel_kit.tar.gz
ADD https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_MODULE_VERSION}.tar.gz /tmp/nginx_lua_module.tar.gz

RUN set -x \
    && tar xvf nginx-${NGINX_VERSION}.tar.gz \
    && tar xvf openresty-${OPENRESTY_VERSION}.tar.gz \
    && tar xvf nginx_devel_kit.tar.gz \
    && tar xvf nginx_lua_module.tar.gz

RUN set -x \
    && cd /tmp/openresty-${OPENRESTY_VERSION} \
    && ./configure -j2 --prefix=/usr/local/openresty \
    && make -j2 \
    && make install

ENV PATH /usr/local/openresty/bin:$PATH
ENV LUAJIT_LIB /usr/local/openresty/luajit/lib
ENV LUAJIT_INC /usr/local/openresty/luajit/include/luajit-2.1

RUN set -x \
    && cd /tmp/nginx-${NGINX_VERSION} \
    && ./configure \
    --user=nobody                          \
    --group=nobody                         \
    --prefix=/etc/nginx                   \
    --sbin-path=/usr/sbin/nginx           \
    --conf-path=/etc/nginx/nginx.conf     \
    --pid-path=/var/run/nginx.pid         \
    --lock-path=/var/run/nginx.lock       \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_gzip_static_module        \
    --with-http_stub_status_module        \
    --with-http_v2_module                  \
    --with-http_ssl_module                \
    --with-pcre                           \
    --with-file-aio                       \
    --with-http_realip_module             \
    --without-http_scgi_module            \
    --without-http_uwsgi_module           \
    --without-http_fastcgi_module ${NGINX_DEBUG:+--debug} \
    --with-cc-opt=-O2 --with-ld-opt='-Wl,-rpath,${LUAJIT_LIB}' \
    --add-module=/tmp/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
    --add-module=/tmp/lua-nginx-module-${NGINX_LUA_MODULE_VERSION} \
    && make install

WORKDIR /etc/nginx

COPY nginx.conf .

RUN nginx -t

RUN set -x \
    && rm -rf /var/cache/apk/* /tmp/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
