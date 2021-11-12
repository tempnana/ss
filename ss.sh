#!/bin/bash
#install snap
apt update && apt upgrade -y
apt install snapd -y
snap install core
#instll shadowsocks-libev
snap install shadowsocks-libev
#get ip
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}
ssport=$(shuf -i 9000-19999 -n 1)
sspwd=$(openssl rand -base64 16)
arr[0]='chacha20-ietf-poly1305'
arr[1]='aes-256-gcm'
arr[2]='aes-192-gcm'
arr[3]='aes-128-gcm'
rand=$(($RANDOM % ${#arr[@]}))
method=${arr[$rand]}
#make ss config file
mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
cat > /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json <<EOF
{
    "server":["::0","0.0.0.0"],
    "server_port":$ssport,
    "password":"$sspwd",
    "method":"$method",
    "mode":"tcp_only",
    "fast_open":false
}
EOF
#auto boot
cat > /etc/systemd/system/shadowsocks-libev-server@.service <<EOF
[Unit]
Description=Shadowsocks-Libev Custom Server Service for %I
After=network-online.target
[Service]
Type=simple
LimitNOFILE=65536
ExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/%i.json
[Install]
WantedBy=multi-user.target
EOF
systemctl enable shadowsocks-libev-server@config
systemctl start shadowsocks-libev-server@config
#systemctl status shadowsocks-libev-server@config
#crontab
rM=$(($RANDOM%59))
echo "$[rM] 4 * * * /sbin/reboot" >> /var/spool/cron/crontabs/root && /etc/init.d/cron restart
#disable log/history/root login
cd && rm -rf /etc/rsyslog.conf && rm -rf /etc/rsyslog.d && rm -rf /etc/init.d/rsyslog && rm -rf /var/log && history -c && export HISTSIZE=0 && cd /etc/ssh && sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" sshd_config && systemctl restart sshd.service && cd
#ufw
apt install ufw -y
# ufw allow ssh
ufw allow "$ssport"
ufw --force enable
#ufw rules checking
ufw status verbose
#ss url
baseurl=$(echo -n "$method:$sspwd@$(get_ip):$ssport" | base64 -w0)
echo '##########'
echo 'ss url is:'
echo '##########'
echo 'ss://'$baseurl'#'$(get_ip)
echo '##########'
echo '#######ss status check:####### '
echo 'systemctl status shadowsocks-libev-server@config'
