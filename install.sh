#! /bin/bash
# 获取当前脚本的软链接路径
SYMLINK_PATH=$(readlink -f "$0")
# DNMP目录
DNMP_DIR=$(dirname "$SYMLINK_PATH")
# 路径转换
DNMP_DIR=$(realpath "$DNMP_DIR")
# .env文件路径
DNMP_ENV=$DNMP_DIR/.env
# 加载公共变量
source $DNMP_DIR/common.sh
# 检查.env文件是否存在 不存在则创建
if [ ! -f "$DNMP_ENV" ] ; then
    cp $DNMP_DIR/env.sample $DNMP_ENV
fi
# 生成密码
MYSQL_ROOT_PASSWORD=$(head -c 15 /dev/urandom | base64 | tr -d '/' | tr -d '=' | tr -d '+')
# 替换.env文件中的MYSQL_ROOT_PASSWORD
sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD/" $DNMP_ENV
# 加载ENV
source $DNMP_ENV

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echoRR "Please run this script with root privileges."
    exit 1
fi

# 卸载旧版本 Docker（如果存在）
echoSB "Remove Old Version Docker."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1
# 更新源
echoSB "Update Source."
apt update
# 安装依赖包
echoSB "Install Necessary Packages."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip gawk zstd pv bc tzdata cron

# 添加 Docker 官方 GPG 密钥 和 仓库
echoSB "Add Docker Official GPG Key and Repository."
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y

# 安装 Docker Engine
echoSB "Install Docker Engine."
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 判断是否安装成功 根据docker 命令是否存在
if [ -x "$(command -v docker)" ]; then
    systemctl start docker
    systemctl enable docker
    echoGC "Docker Install Success."
    echoSB "Start Docker Compose Service."
    cd $DNMP_DIR
    docker compose down >/dev/null 2>&1
    docker compose up -d
else
    echoRR "Docker Install Failed."
    exit 1
fi

# 创建软链接
rm -rf /usr/local/bin/vhost.sh
chmod +x $DNMP_DIR/vhost.sh
ln -s $DNMP_DIR/vhost.sh /usr/local/bin/vhost.sh
