## Nginx + OpenResty Docker Image

- Nginx v1.17.10
- OpenRest v1.15.8.3

https://hub.docker.com/r/raniellyf/nginx-resty
```sh
$ docker push raniellyf/nginx-resty:latest
```

Documentaçao OpenRest

https://github.com/openresty/lua-nginx-module

Adicione no bloco http
```
lua_package_path "/usr/local/openresty/lualib/?.lua;/usr/local/include/lua/?.lua;;";
```