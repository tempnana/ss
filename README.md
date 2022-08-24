# ss
(Debian9/10) is tested
<li>Install Shadowsocks-libev Via Snap</li>
<li>Kcptun is configured</li>
<li>udp2raw is configured</li>
<br>
<b>Install Shadowsocks-libev + Kcptun + udp2raw:</b>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss-kcptun-udp2raw.sh)
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
