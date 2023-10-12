#!/bin/bash
# 开放端口
ufw disable
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades
#sudo ufw allow 22,80,443,8096,8095,5244/tcp
#sudo ufw enable

# 记录脚本开始时间
start_time=$(date +%s)

local_ip=$(curl -4 ip.gs)
# 指定输出日志文件
config_file="/root/config_info.txt"
log_file="/root/install_log.txt"
mkdir -p /root/emby
cd /root/emby
# 创建一个空的步骤日志文件
echo "" > "$log_file"
echo "" > "$config_file"

# 第一步：升级软件源
echo -e "\e[32mStep 1: Updating software sources...\e[0m"
apt update -y && apt install -y curl wget sudo socat vim unzip jq git fuse3
echo -e "\e[32mStep 1: Software sources updated and necessary tools installed.\e[0m"
# 保存步骤输出到步骤日志文件
echo "Step 1: Software sources updated and necessary tools installed." >> "$log_file"

# 开启BBR
uname -r
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
# 保存步骤输出到步骤日志文件
echo -e "\e[32mBBR configuration applied.\e[0m"
echo "Step 2: BBR configuration applied." >> "$log_file"




# 安装git-lfs
#echo -e "\e[32mStep 4: Installing Git LFS...\e[0m"
#curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
#apt-get install git-lfs -y
#echo -e "\e[32mStep 4: Git LFS installed.\e[0m"
# 保存步骤输出到步骤日志文件
#echo "Step 4: Git LFS installed." >> "$log_file"

# 第二步：安装 Emby
echo -e "\e[32mStep 3: Installing Emby...\e[0m"
wget https://github.com/MediaBrowser/Emby.Releases/releases/download/4.7.14.0/emby-server-deb_4.7.14.0_amd64.deb
dpkg -i emby-server-deb_4.7.14.0_amd64.deb
echo -e "\e[32mStep 3: Emby Server installed. Access it at http://${local_ip}:8096.\e[0m"
# 保存步骤输出到步骤日志文件
echo "Step 3: Emby Server installed. Access it at http://${local_ip}:8096." >> "$log_file"

# 第三步：安装 Alist
echo -e "\e[32mStep 4: Installing Alist...\e[0m"
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install
cd /opt/alist && ./alist admin set Lmyy2024.
echo -e "\e[32mStep 4: Alist Server installed. Access it at http://${local_ip}:5244.\e[0m"
# 保存步骤输出到步骤日志文件
echo "Step 4: Alist Server installed. Access it at http://${local_ip}:5244." >> "$log_file"
systemctl restart alist
# 第四步：安装 rclone
echo -e "\e[32mStep 5: Installing rclone...\e[0m"
curl https://rclone.org/install.sh | sudo bash
echo -e "\e[32mStep 5: rclone Server installed. Access it at rclone config.\e[0m"
# 保存步骤输出到步骤日志文件
echo "Step 5: rclone Server installed. Access it at rclone config." >> "$log_file"

# 克隆文件存储库 备份 可选
echo -e "\e[32mStep 6: Cloning fileRepo...\e[0m"
cd /root/emby
git clone https://github.com/dameng9779/fileRepo.git
#cd fileRepo
#git lfs pull
#echo -e "\e[32mStep 9: FileRepo cloned and Git LFS data pulled."
echo -e "\e[32mStep 6: Cloning fileRepo finished \e[0m"
#生成alist-token
echo -e "\e[32mStep 7: Reset alist password...\e[0m"
cd /opt/alist && ./alist admin set Lmyy2024.
# 构建请求JSON数据
request_data='{
  "username": "admin",
  "password": "Lmyy2024."
}'
echo -e "\e[32mStep 7: Reset alist password success. username:admin password:Lmyy2024.\e[0m"
echo "Step 7: Reset alist password success. username:admin password:Lmyy2024." >> "$log_file"
# 发送HTTP POST请求
token=$(curl --silent --request POST --header 'Content-Type: application/json' --data "$request_data" "http://${local_ip}:5244/api/auth/login" | jq -r '.data.token')

echo "Token: $token"


echo -e "\e[32mStep 8: Get alist token...\e[0m"
alisttoken=$(curl --silent --request GET --header "Authorization: ${token}" "http://${local_ip}:5244/api/admin/setting/list?group=0" | jq -r '.data[] | select(.key == "token") | .value' )
echo "alisttoken: $alisttoken"
echo -e "\e[32mStep 8: Get alist token success\e[0m"
echo "Step 8: Get alist token success" >> "$log_file"
echo "alisttoken: $alisttoken " >> "$log_file"
echo "alist-token: $alisttoken " >> "$config_file"


cd /root/emby/fileRepo

echo -e "\e[32mStep 9: Emby crack...\e[0m"
#替换emby-crack破解emby
cp -r /root/emby/fileRepo/embyserver_4_7_14_0_native_auth/* /opt/emby-server/system
systemctl restart emby-server
echo -e "\e[32mStep 9: Emby crack success\e[0m"
echo -e "Step 9: Emby crack success and server restarted" >> "$log_file"



# 安装docker
echo -e "\e[32mStep 10: Installing Docker...\e[0m"
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
echo -e "\e[32mStep 10: Docker installed.\e[0m"
# 保存步骤输出到步骤日志文件
echo "Step 10: Docker installed." >> "$log_file"

# 创建emby账号 emby/emby
# 定义服务名称
service_name="emby-server"

# 最长等待时间（以秒为单位）
max_wait_time=20

# 检查服务状态是否为 active
if systemctl is-active --quiet $service_name; then
    echo "Service $service_name is active."

    # 等待 20 秒
    sleep $max_wait_time

    echo "Continuing with your action..."
    # 在这里执行你的脚本或命令
else
    echo "Service $service_name is not active. Exiting..."
    sleep 40
fi




chmod +x emby-init.sh
./emby-init.sh
echo -e "\e[32mEmby account save success , username:emby ,password:emby\e[0m"
echo -e "Emby account save success , username:emby ,password:emby" >> "$log_file"

echo -e "Step 11: Emby crack success and server restarted" >> "$log_file"
# 执行nginx脚本
chmod +x ./nginx.sh
./nginx.sh 

echo -e "Step 12: Emby2Alist nginx success" >> "$log_file"

echo -e "\e[32mStep 13: Emby beautify...\e[0m"
# 美化
chmod +x beautify.sh
./beautify.sh
echo -e "\e[32mStep 13: Emby beautify success\e[0m"
echo -e "Step 13: Emby beautify success" >> "$log_file"


# 安装TG插件
echo -e "\e[32mStep 14: Emby TG Plugin install...\e[0m"
cp /root/emby/fileRepo/Emby.Plugin.TelegramNotification.dll /var/lib/emby/plugins
systemctl restart emby-server
echo -e "\e[32mStep 14: Emby TG Plugin installed\e[0m"
echo -e "Step 13: Emby TG Plugin installed and server restarted" >> "$log_file"

echo -e "\e[32mAll done\e[0m"
echo "All done" >> "$log_file"
echo "Please go to Alist to create the corresponding repository and execute rclone to configure the mount." >> "$log_file"
mkdir -p /data
echo "Rclone Command：rclone mount webdav:/ /data --cache-dir /tmp --allow-other --vfs-cache-mode writes --allow-non-empty --header "Referer: https://www.aliyundrive.com/"" >> "$log_file"
echo "Visit http://${local_ip}:8096/web/index.html#!/dashboard to add the media library" >> "$log_file"
# 合并所有步骤的输出到最终日志文件

cat "$log_file"
# 记录脚本结束时间
end_time=$(date +%s)

# 计算总运行时间
total_time=$((end_time - start_time))

# 将总运行时间转化为人类可读格式
minutes=$((total_time / 60))
seconds=$((total_time % 60))
echo -e "\e[32m总共耗时${minutes}分${seconds}秒\e[0m"
