#!/bin/bash

# # install snap
update_install() {
    mkdir -p /var/log/apt/
    apt update && apt upgrade -y
    apt install snapd ufw -y
    snap install core
}

# # get ip
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}

# # install shadowsocks
install_shadowsocks() {
    ssport=$(shuf -i 9000-19999 -n 1)
    sspwd=$(openssl rand -base64 16)
    arr[0]='chacha20-ietf-poly1305'
    arr[1]='aes-256-gcm'
    arr[2]='aes-128-gcm'
    rand=$(($RANDOM % ${#arr[@]}))
    method=${arr[$rand]}
    # # install shadowsocks
    snap install shadowsocks-libev
    # # make ss config file
    mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
    cat >/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json <<EOF
{
    "server":["::0","0.0.0.0"],
    "server_port":${ssport},
    "password":"${sspwd}",
    "method":"${method}",
    "mode":"tcp_and_udp",
    "fast_open":false
}
EOF
    # # auto boot
    cat >/etc/systemd/system/shadowsocks-libev-server@.service <<EOF
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
    # systemctl status shadowsocks-libev-server@config
}

# # install kcptun
install_kcptun() {
    echo ulimit -n 65535 >>/etc/profile
    source /etc/profile

    # # Suggested sysctl.conf parameters for better handling of UDP packets:
    echo 'net.core.rmem_max=26214400' >>/etc/sysctl.conf
    echo 'net.core.rmem_default=26214400' >>/etc/sysctl.conf
    echo 'net.core.wmem_max=26214400' >>/etc/sysctl.conf
    echo 'net.core.wmem_default=26214400' >>/etc/sysctl.conf
    echo 'net.core.netdev_max_backlog=2048' >>/etc/sysctl.conf
    /sbin/sysctl -p

    # # isntall kcptun
    mkdir -p /usr/local/kcptun
    cd /usr/local/kcptun
    wget https://github.com/xtaci/kcptun/releases/download/v20230214/kcptun-linux-amd64-20230214.tar.gz
    tar -zxvf kcptun-linux-amd64-20230214.tar.gz

    # set kcptun port/password
    kcport=$(shuf -i 20000-29999 -n 1)
    kcpwd=$(openssl rand -base64 16)

    # # set kcptun server config file
    cat >server-config.json <<EOF
{
"listen": ":${kcport}",
"target": "127.0.0.1:${ssport}",
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
"sockbuf": 16777217,
"keepalive": 10
}
EOF

    # # make kcptun client config file
    cat >client-config.json <<EOF
{
"localaddr": ":${ssport}",
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
"sockbuf": 16777217,
"keepalive": 10
}
EOF

    # # run
    chmod +x server_linux_amd64
    ./server_linux_amd64 -c /usr/local/kcptun/server-config.json >/dev/null 2>&1 &

    # # auto boot
    cd /etc/init.d/
    cat >autokcp <<EOF
#!/bin/sh

### BEGIN INIT INFO
# Provides: autokcp
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: autokcp
# Description: autokcp
### END INIT INFO
#chmod +x autokcp
#update-rc.d autokcp defaults
#update-rc.d -f autokcp remove
sleep 60
/usr/local/kcptun/server_linux_amd64 -c /usr/local/kcptun/server-config.json 2>&1 &

exit 0

EOF
    chmod +x autokcp
    update-rc.d autokcp defaults
}

# # set crontab
set_crontab() {
    rM=$(($RANDOM % 59))
    echo "$((rM)) 4 * * * /sbin/reboot" >>/var/spool/cron/crontabs/root && /etc/init.d/cron restart
}

# # set ufw
set_ufw() {
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow ${ssport}
    ufw allow ${kcport}
    ufw status verbose
    systemctl disable netfilter-persistent
    systemctl start ufw
    systemctl enable ufw
}

# # disable log and ssh login
set_log_ssh() {
    cd && rm -rf /etc/rsyslog.conf && rm -rf /etc/rsyslog.d && rm -rf /etc/init.d/rsyslog && rm -rf /var/log && history -c && export HISTSIZE=0
    cd /etc/ssh && sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" sshd_config && systemctl restart sshd.service && cd
    ufw deny ssh
}

# # get shadowsocks config
get_shadowsocks_config() {
    echo ''
    if [[ -f "/usr/local/kcptun/server-config.json" ]]; then
        ss_ip='127.0.0.1'
    else
        ss_ip=$(get_ip)
    fi
    baseurl=$(echo -n "${method}:${sspwd}@${ss_ip}:${ssport}" | base64 -w0)
    ss_url="ss://${baseurl}#$(get_ip)"
    echo '#### shadowsocks url is:'
    echo -e "\033[1;33m${ss_url}\033[0m"
    echo ''
}

# # get kcptun config
get_kcptun_config() {
    view_kcptunconfig=$(cat /usr/local/kcptun/client-config.json)
    echo '#### kcptun client config is:'
    echo -e "\033[1;33m${view_kcptunconfig}\033[0m"
    echo ''
    mbaseurl=$(echo -n "${method}:${sspwd}@$(get_ip):${kcport}" | base64 -w0)
    ss_m_url="ss://${baseurl}#$(get_ip)"
    echo '#### mobile shadowsocks url is:'
    echo -e "\033[1;33m${ss_m_url}\033[0m"
    echo ''
    echo '#### mobile kcptun client config:'
    kcptun_m_config="key=${kcpwd};crypt=aes;mode=fast;mtu=1350;sndwnd=1024;rcvwnd=1024;datashard=70;parityshard=30;dscp=46;interval=40;sockbuf=16777217;keepalive=10"
    echo -e "\033[1;33m${kcptun_m_config}\033[0m"
    echo ''
    echo 'Add more kcptun config:'
    echo 'bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/kcpadd.sh)'
}

# # add more kcptun
add_more_kcptun() {
    bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/kcpadd.sh)
}

default_install() {
    update_install
    install_shadowsocks
    install_kcptun
    set_crontab
    set_ufw
    set_log_ssh
    get_shadowsocks_config
    get_kcptun_config
}

echo "Choose install:"
echo ""
echo " 1: Install Shadowsocks + Kcptun"
echo " 2: Only install Shadowsocks"
echo " 3: Only install Kcptun"
echo " 4: Add more Kcptun"
echo ""
read -p "(Directly Enter to install Shadowsocks + kcptun), Enter 1 or 2,3,4:" install
if [[ '1' = "$install" ]]; then
    default_install
elif [[ '2' = "$install" ]]; then
    update_install
    install_shadowsocks
    ufw allow ${ssport}
    get_shadowsocks_config
elif [[ '3' = "$install" ]]; then
    install_kcptun
    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${kcport}
    fi
    get_kcptun_config
elif [[ '4' = "$install" ]]; then
    add_more_kcptun
else
    default_install
fi

exit
