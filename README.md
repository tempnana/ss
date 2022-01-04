# ss
(Debian9/10) is tested
<li>Install Shadowsocks-libev Via Snap</li>
<li>Kcptun is configured</li>
<li>udp2raw is configured</li>
<br>
<p>Install Shadowsocks-libev + Kcptun + udp2raw:</p>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss-kcptun-udp2raw.sh)
</pre>
<br>
<p>Install Shadowsocks-libev + Kcptun:</p>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss-kcptun.sh)
</pre>
<br>
<p>Only Install Shadowsocks-obfs:</p>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss-obfs.sh)
</pre>
<br>
<p>Only Install Shadowsocks-libev:</p>
<pre>
bash <(wget -qO- https://raw.githubusercontent.com/tempnana/ss/main/ss.sh)
</pre>
<br>
<p>Other Shadowsocks-libev:</p>
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
