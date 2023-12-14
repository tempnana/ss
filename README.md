# ss
<b>(Debian 9/10/11) is tested</b>
<li>Install Shadowsocks-libev Via Snap</li>
<li>Kcptun is configured</li>
<li>udp2raw is configured</li>
<br>
<b>Recommended installation in Screen.</b>
<br>
<pre>
apt install screen -y
</pre>
<pre>
screen -S ss
</pre>
<hr>
<br>
<b>Install:</b>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/install.sh)
</pre>
<b>Install Shadowsocks-libev + Kcptun:</b>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss-kcptun.sh)
</pre>
<b>Only Install Shadowsocks-libev:</b>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss.sh)
</pre>
<b>Other server add Shadowsocks-libev:</b>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/s.sh)
</pre>
<!--
<br>
<p>Manage it:</p>
<pre>
systemctl start snap.shadowsocks-libev.ss-server-daemon.service
systemctl stop snap.shadowsocks-libev.ss-server-daemon.service
systemctl restart snap.shadowsocks-libev.ss-server-daemon.service
systemctl status snap.shadowsocks-libev.ss-server-daemon.service
</pre>
-->
<br>
<b>Only kcptun:</b>
<br>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/kcponly.sh)
</pre>
