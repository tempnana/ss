#!/bin/bash
cd /usr/local/kcptun
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}
kcport=$(shuf -i 20000-29999 -n 1)
kcpwd=$(openssl rand -base64 16)
configlist=$(ls server-config*)
echo 'server-config list:' $configlist
read -p "Enter target ip port and config file number. eg:1.1.1.1 1111 1 > " rip rport confnum
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
sed -i '/exit 0/i\( ( /usr/local/kcptun/server_linux_amd64 -c /usr/local/kcptun/server-config'$confnum'.json 2>&1 & )  )' /etc/rc.local
systemctl restart rc-local.service
ufw allow "$kcport"
ufw --force enable
./server_linux_amd64 -c /usr/local/kcptun/server-config.json >/dev/null 2>&1 &
echo "server-config${confnum}.json started."
echo 'kcptun client config:'
echo '##########'
cat client-config${confnum}.json
echo '##########'
echo 'Add more kcptun config:'
echo 'bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/kcpadd.sh)'
exit
