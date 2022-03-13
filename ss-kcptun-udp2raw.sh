#!/bin/bash
#install snap
apt update && apt upgrade -y
apt install snapd -y
snap install core
#install shadowsocks-libev
snap install shadowsocks-libev
#get ip
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}
#set shadowsocks-libev port/password/method
ssport=$(shuf -i 9000-19999 -n 1)
sspwd=$(openssl rand -base64 16)
arr[0]='chacha20-ietf-poly1305'
arr[1]='aes-256-gcm'
arr[2]='aes-192-gcm'
arr[3]='aes-128-gcm'
rand=$(($RANDOM % ${#arr[@]}))
method=${arr[$rand]}
#make shadowsocks-libev config file
mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
cat > /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json <<EOF
{
    "server":["::0","0.0.0.0"],
    "server_port":$ssport,
    "password":"$sspwd",
    "method":"$method",
    "mode":"tcp_and_udp",
    "fast_open":false
}
EOF
#make system service
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
systemctl start shadowsocks-libev-server@config &
#systemctl status shadowsocks-libev-server@config
#################################
###kcptun
#################################
mkdir -p /usr/local/kcptun
cd /usr/local/kcptun
# wget https://github.com/xtaci/kcptun/releases/download/v20210103/kcptun-linux-amd64-20210103.tar.gz
wget https://github.com/xtaci/kcptun/releases/download/v20210624/kcptun-linux-amd64-20210624.tar.gz
tar -zxvf kcptun-linux-amd64-20210624.tar.gz
#set kcptun port/password
kcport=$(shuf -i 20000-29999 -n 1)
kcpwd=$(openssl rand -base64 10)
#make kcptun server config file
cat > server-config.json <<EOF
{
"listen": ":${kcport}",
"target": "127.0.0.1:${ssport}",
"key": "${kcpwd}",
"crypt": "aes-128",
"mode": "fast2",
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
cat > client-config.json <<EOF
{
"localaddr": ":${ssport}",
"remoteaddr": "127.0.0.1:${kcport}",
"key": "${kcpwd}",
"crypt": "aes-128",
"mode": "fast2",
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
#################################
###udp2raw
#################################
mkdir -p /usr/local/udp2raw
cd /usr/local/udp2raw
wget https://github.com/wangyu-/udp2raw/releases/download/20200818.0/udp2raw_binaries.tar.gz
tar -zxvf udp2raw_binaries.tar.gz
#set udp2raw port/password
udp2rawport=$(shuf -i 30000-39999 -n 1)
udp2rawpwd=$(openssl rand -base64 10)
#make udp2raw server config file
cat > server.conf <<EOF
-s
-l 0.0.0.0:${udp2rawport}
-r 127.0.0.1:${kcport}
-a
-k ${udp2rawpwd}
--raw-mode faketcp
EOF
#make udp2raw lient config file
cat > client.conf <<EOF
-c
-r $(get_ip):${udp2rawport}
-l 127.0.0.1:${kcport}
-a
-k ${udp2rawpwd}
--raw-mode faketcp
EOF
#run
chmod +x udp2raw_amd64
./udp2raw_amd64 --conf-file server.conf 2>&1 &
#auto boot
cat > /etc/rc.local << EOF
#!/bin/bash -e
#
# rc.local
#
# By default this script does nothing.
# kcptun
( ( /usr/local/kcptun/server_linux_amd64 -c /usr/local/kcptun/server-config.json 2>&1 & )  )
sleep 15s
# udp2raw
( ( /usr/local/udp2raw/udp2raw_amd64 --conf-file /usr/local/udp2raw/server.conf 2>&1 & )  )
exit 0
EOF
chmod +x /etc/rc.local
systemctl enable rc-local &
systemctl start rc-local.service &
# systemctl status rc-local.service
#crontab
rM=$(($RANDOM%59))
echo "$[rM] 4 * * * /sbin/reboot" >> /var/spool/cron/crontabs/root && /etc/init.d/cron restart
#disable log/history/root login
cd && rm -rf /etc/rsyslog.conf && rm -rf /etc/rsyslog.d && rm -rf /etc/init.d/rsyslog && rm -rf /var/log && history -c && export HISTSIZE=0 && cd /etc/ssh && sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" sshd_config && systemctl restart sshd.service && cd
#firewall
apt install ufw -y
# ufw allow ssh
ufw allow "$ssport"
ufw allow "$kcport"
ufw allow "$udp2rawport"
ufw --force enable
# checking rules
ufw status verbose
# end
### More settings:
###ufw
#ufw disable
###ufw
# ufw reset
#ss url
baseurl=$(echo -n "$method:$sspwd@127.0.0.1:$ssport" | base64 -w0)
echo '##########'
echo 'ss url is:'
echo '##########'
echo 'ss://'$baseurl'#'$(get_ip)
echo '##########'
echo 'kcptun client config(save to xxx.json):'
#./client -c xxx.json
echo '##########'
cat /usr/local/kcptun/client-config.json
echo '##########'
echo 'udp2raw client config(save to xxx.conf):'
#./udp2raw_amd64 --conf-file xxx.conf
echo '##########'
cat /usr/local/udp2raw/client.conf
echo '##########'
echo '#######ss status check:####### '
echo 'systemctl status shadowsocks-libev-server@config'
