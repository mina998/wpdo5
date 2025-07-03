# 用户和组
ARG USER=www-data
ARG GROUP=www-data
ARG TZ="Asia/Shanghai"

#################
###  Certbot  ###
#################
FROM certbot/certbot:latest AS certbot
ARG USER
ARG GROUP
ARG TZ

WORKDIR /wwwroot
EXPOSE 80 
STOPSIGNAL SIGQUIT

# 覆盖默认的入口点，允许运行自定义命令
ENTRYPOINT []
# 保持容器运行，而不是执行帮助命令后退出
CMD ["tail", "-f", "/dev/null"]
