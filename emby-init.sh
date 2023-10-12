#!/bin/bash

local_ip=$(curl -4 ip.gs)

# 调用第一个接口
curl --silent --request POST --url "http://${local_ip}:8096/emby/Startup/User" --form 'Name="emby"' --form 'Password="emby"'
curl --silent --request POST --url "http://${local_ip}:8096/emby/Startup/Configuration" --form 'UICulture="zh-CN"'  --form 'MetadataCountryCode="US"' --form 'PreferredMetadataLanguage="en"'
curl --silent --request POST --url "http://${local_ip}:8096/emby/Startup/RemoteAccess" --form 'EnableAutomaticPortMapping="true"'
curl --silent --request POST --url "http://${local_ip}:8096/emby/Startup/Complete"
emby_access_token=$(curl --silent --request POST --url "http://${local_ip}:8096/emby/Users/authenticatebyname?X-Emby-Client=Emby%20Web&X-Emby-Device-Name=Chrome%20Windows&X-Emby-Device-Id=1&X-Emby-Client-Version=4.7.14.0&X-Emby-Language=zh-cn" --form 'Username="emby"' --form 'Pw="emby"' | jq -r '.AccessToken')
echo "$emby_access_token"
