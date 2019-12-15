FROM alpine:3.10.3
RUN apk update && \
    apk upgrade && \
    apk add nginx && \
    mkdir -p /usr/share/nginx/html
COPY ./index.html /usr/share/nginx/html/index.html
COPY ./nginx.conf /etc/nginx/nginx.conf    
COPY ./default.conf /etc/nginx/conf.d/default.conf
VOLUME /usr/share/nginx/html /var/log/nginx
EXPOSE 80 443      
CMD ["nginx", "-g", "daemon off;"]
