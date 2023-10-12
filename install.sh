#!/bin/bash

# 指定输出日志文件
config_file="/root/config_info.txt"
log_file="/root/install_log.txt"
mkdir -p /root/emby
cd /root/emby
# 创建一个空的步骤日志文件
echo "" > "$log_file"
echo "" > "$config_file"

# 第一步：升级软件源
echo "Step 1: Updating software sources..."
apt update -y && apt install -y curl wget sudo socat vim unzip fq git fuse3
echo "Step 1: Software sources updated and necessary tools installed."
# 保存步骤输出到步骤日志文件
echo "Step 1: Software sources updated and necessary tools installed." >> "$log_file"

# 开启BBR
uname -r
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
# 保存步骤输出到步骤日志文件
echo "BBR configuration applied." >> "$log_file"


# 安装docker
echo "Step 4: Installing Docker..."
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
echo "Step 4: Docker installed."
# 保存步骤输出到步骤日志文件
echo "Step 4: Docker installed." >> "$log_file"

# 安装git-lfs
echo "Step 5: Installing Git LFS..."
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
apt-get install git-lfs -y
echo "Step 5: Git LFS installed."
# 保存步骤输出到步骤日志文件
echo "Step 5: Git LFS installed." >> "$log_file"

# 第二步：安装 Emby
echo "Step 6: Installing Emby..."
wget https://github.com/MediaBrowser/Emby.Releases/releases/download/4.7.14.0/emby-server-deb_4.7.14.0_amd64.deb
dpkg -i emby-server-deb_4.7.14.0_amd64.deb
echo "Step 6: Emby Server installed. Access it at http://localhost:8096."
# 保存步骤输出到步骤日志文件
echo "Step 6: Emby Server installed. Access it at http://localhost:8096." >> "$log_file"

# 第三步：安装 Alist
echo "Step 7: Installing Alist..."
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install
cd /opt/alist && ./alist admin set Lmyy2024.
echo "Step 7: Alist Server installed. Access it at http://localhost:5244."
# 保存步骤输出到步骤日志文件
echo "Step 7: Alist Server installed. Access it at http://localhost:5244." >> "$log_file"

# 第四步：安装 rclone
echo "Step 8: Installing rclone..."
curl https://rclone.org/install.sh | sudo bash
echo "Step 8: rclone Server installed. Access it at rclone config."
# 保存步骤输出到步骤日志文件
echo "Step 8: rclone Server installed. Access it at rclone config." >> "$log_file"

# 克隆文件存储库 备份 可选
echo "Step 9: Cloning fileRepo..."
git clone https://github.com/dameng9779/fileRepo.git
#cd fileRepo
#git lfs pull
#echo "Step 9: FileRepo cloned and Git LFS data pulled."

#生成alist-token
cd /opt/alist && ./alist admin set Lmyy2024.
local_ip=$(curl -4 ip.gs)
# 构建请求JSON数据
request_data='{
  "username": "admin",
  "password": "Lmyy2024."
}'

# 发送HTTP POST请求
token=$(curl --silent --request POST --header 'Content-Type: application/json' --data "$request_data" "http://${local_ip}:5244/api/auth/login" | jq -r '.data.token')

echo "Token: $token"


alisttoken=$(curl --silent --request GET --header "Authorization: ${token}" "http://${local_ip}:5244/api/admin/setting/list?group=0" | jq -r '.data[] | select(.key == "token") | .value' )
echo "alisttoken: $alisttoken"
echo "alisttoken: $alisttoken " >> "$log_file"
echo "alist-token: $alisttoken " >> "$config_file"



# 输出提示信息
echo "Please visit Emby at http://localhost:8096 and create an account. After creating an account, please enter the required value."

cd /root/emby/fileRepo


#替换emby-crack破解emby
cp -r /root/emby/fileRepo/embyserver_4_7_14_0_native_auth/* /opt/emby-server/system
systemctl restart emby-server


# 读取用户输入
read user_input
chmod +x nginx.sh
# 执行另一个脚本，将用户输入的值作为参数传递
./nginx.sh "$user_input"


# 美化
chmod +x beautify.sh
./beautify.sh

echo "All done" >> "$config_file"

# 合并所有步骤的输出到最终日志文件
cat "$log_file"
