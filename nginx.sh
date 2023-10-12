#!/bin/bash
config_file="/root/config_info.txt"
cd /root/emby/fileRepo
# 获取外部传入的 X-Emby-Token
x_emby_token="$1"

if [ -z "$x_emby_token" ]; then
    echo "X-Emby-Token is missing. Please provide the X-Emby-Token as a parameter when running the script."
    exit 1
fi

# 获取本机IP地址
local_ip=$(curl -4 ip.gs)

# 调用第一个接口
curl --silent --request POST --url "http://${local_ip}/emby/Auth/Keys?App=emby&X-Emby-Token=${x_emby_token}"

# 调用第二个接口，获取响应并提取AccessToken
response=$(curl --silent --request GET --url "http://${local_ip}/emby/Auth/Keys?X-Emby-Token=${x_emby_token}")
emby_key=$(echo "$response" | jq -r '.Items[] | select(.AppName == "emby") | .AccessToken')

# 输出AccessToken

echo "AccessToken: $emby_key"
echo "emby-key: $emby_key" >> "$config_file"




#########################
#获取token开始配置nginx
alisttoken=$(grep -o 'alisttoken: [^ ]*' /root/install_log.txt | awk '{print $2}')
echo $alisttoken

sed -i "s|const alistToken = '.*';|const alistToken = '${alisttoken}';|" /root/emby/fileRepo/nginx/conf.d/emby.js
sed -i "s|const embyApiKey = '.*';|const embyApiKey = '${emby_key}';|" /root/emby/fileRepo/nginx/conf.d/emby.js
sed -i "s|const alistPublicAddr = 'http://youralist.com:5244';|const alistPublicAddr = 'http://${local_ip}:5244';|" /root/emby/fileRepo/nginx/conf.d/emby.js

#启动nginx
awk '/version: '\''3.5'\''/,/restart: always/' docker-compose.yml > new_docker_compose_file.yml && mv new_docker_compose_file.yml docker-compose.yml
docker compose up -d

