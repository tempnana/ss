#!/bin/bash
#install snap
apt update && apt upgrade -y
#get ip
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}
#################################
###kcptun
#Increase the number of open files on your server,
echo ulimit -n 65535 >> /etc/profile
source /etc/profile
#Suggested sysctl.conf parameters for better handling of UDP packets:
echo 'net.core.rmem_max=26214400' >> /etc/sysctl.conf
echo 'net.core.rmem_default=26214400' >> /etc/sysctl.conf
echo 'net.core.wmem_max=26214400' >> /etc/sysctl.conf
echo 'net.core.wmem_default=26214400' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=2048' >> /etc/sysctl.conf
/sbin/sysctl -p
#################################
mkdir -p /usr/local/kcptun
cd /usr/local/kcptun
# wget https://github.com/xtaci/kcptun/releases/download/v20210103/kcptun-linux-amd64-20210103.tar.gz
wget https://github.com/xtaci/kcptun/releases/download/v20210624/kcptun-linux-amd64-20210624.tar.gz
tar -zxvf kcptun-linux-amd64-20210624.tar.gz
#set kcptun port/password
kcport=$(shuf -i 20000-29999 -n 1)
kcpwd=$(openssl rand -base64 16)
#make kcptun server config file
configlist=$(ls server-config*)
echo 'server-config list:' $configlist
read -p "Enter target ip porot and config file number. eg:1.1.1.1 1111 1 > " rip rport confnum
cat > server-config${confnum}.json <<EOF
{
"listen": ":${kcport}",
"target": "${rip}:${rport}",
"key": "${kcpwd}",
"crypt": "aes",
"mode": "fast",
"mtu": 1350,
"sndwnd": 1024,
"rcvwnd": 1024,
"datashard": 70,
"parityshard": 30,
"dscp": 46,
"nocomp": false,
"acknodelay": false,
"nodelay": 0,
"interval": 40,
"resend": 0,
"nc": 0,
"sockbuf": 4194304,
"keepalive": 10
}
EOF
#make kcptun client config file
cat > client-config${confnum}.json <<EOF
{
"localaddr": ":${rport}",
"remoteaddr": "$(get_ip):${kcport}",
"key": "${kcpwd}",
"crypt": "aes",
"mode": "fast",
"mtu": 1350,
"sndwnd": 1024,
"rcvwnd": 1024,
"datashard": 70,
"parityshard": 30,
"dscp": 46,
"nocomp": false,
"acknodelay": false,
"nodelay": 0,
"interval": 40,
"resend": 0,
"nc": 0,
"sockbuf": 4194304,
"keepalive": 10
}
EOF
#run
chmod +x server_linux_amd64
./server_linux_amd64 -c /usr/local/kcptun/server-config.json 2>&1 &
#auto boot
cat > /etc/rc.local << EOF
#!/bin/bash -e
#
# rc.local
#
# By default this script does nothing.
# kcptun
( ( /usr/local/kcptun/server_linux_amd64 -c /usr/local/kcptun/server-config.json 2>&1 & )  )
exit 0
EOF
chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local.service
systemctl status rc-local.service
#crontab
rM=$(($RANDOM%59))
echo "$[rM] 4 * * * /sbin/reboot" >> /var/spool/cron/crontabs/root && /etc/init.d/cron restart
#disable log/history/root login
cd && rm -rf /etc/rsyslog.conf && rm -rf /etc/rsyslog.d && rm -rf /etc/init.d/rsyslog && rm -rf /var/log && history -c && export HISTSIZE=0
cd /etc/ssh && sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" sshd_config && systemctl restart sshd.service && cd
#ufw
apt install ufw -y
# ufw allow ssh
ufw allow "$kcport"
ufw --force enable
#ufw rules checking
ufw status verbose
# end
### More settings:
###
#ufw disable
###
# ufw reset
#kcptun client config
echo "server-config${confnum}.json started."
echo 'kcptun client config:'
echo '##########'
cat client-config${confnum}.json
echo '##########'
echo 'Add more kcptun config:'
echo 'bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/addkcp.sh)'
exit
