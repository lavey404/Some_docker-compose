#!/bin/bash
# FTP服务自动化部署脚本
# 功能：安装vsftpd，创建用户ftpuser，指定专属目录，禁用匿名访问

# 定义配置参数
FTP_USER="ftpuser"
FTP_PASS="password"
FTP_DIR="/home/ftp"

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo运行此脚本"
    exit 1
fi

# 创建系统用户（禁止shell登录）
chmod  755 /home/ftp
echo "/usr/sbin/nologin" | sudo tee -a /etc/shells
useradd -d $FTP_DIR -s /usr/sbin/nologin $FTP_USER
echo "$FTP_USER:$FTP_PASS" | chpasswd
sudo sed -i 's/^auth\s\+required\s\+pam_shells.so/# &/' /etc/pam.d/vsftpd

# 更新系统并安装vsftpd
apt update && apt install -y vsftpd

# 创建FTP专用目录
#mkdir -p $FTP_DIR
chown -R $FTP_USER:$FTP_USER $FTP_DIR
chmod 755 $FTP_DIR

# 备份原始配置文件
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

# 生成新配置文件
tee /etc/vsftpd.conf << EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=$FTP_DIR
pasv_min_port=50000
pasv_max_port=50100
EOF

# 重启服务并设置开机启动
systemctl restart vsftpd
systemctl enable vsftpd

echo "FTP服务部署完成！"
echo "访问信息："
echo "地址: $(hostname -I | awk '{print $1}')"
echo "用户名: $FTP_USER"
echo "密码: $FTP_PASS"
echo "专属目录: $FTP_DIR"
