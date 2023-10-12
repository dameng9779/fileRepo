#!/bin/bash
config_file="/root/config_info.txt"
cd /root/emby/fileRepo

# 获取本机IP地址
local_ip=$(curl -4 ip.gs)

emby_access_token=$(curl --silent --request POST --url "http://${local_ip}:8096/emby/Users/authenticatebyname?X-Emby-Client=Emby%20Web&X-Emby-Device-Name=Chrome%20Windows&X-Emby-Device-Id=1&X-Emby-Client-Version=4.7.14.0&X-Emby-Language=zh-cn" --form 'Username="emby"' --form 'Pw="emby"' | jq -r '.AccessToken')
echo "$emby_access_token"

# 调用第一个接口
curl --silent --request POST --url "http://${local_ip}:8096/emby/Auth/Keys?App=emby&X-Emby-Token=${emby_access_token}"

# 调用第二个接口，获取响应并提取AccessToken
response=$(curl --silent --request GET --url "http://${local_ip}:8096/emby/Auth/Keys?X-Emby-Token=${emby_access_token}")
emby_key=$(echo "$response" | jq -r '.Items[] | select(.AppName == "emby") | .AccessToken')

# 输出AccessToken
echo "GetKeyResponse: $response"
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
