
cat > /etc/rsyslog.d/100-customized-ipt.conf << __EOF__
:msg, contains, "[IPTABLES]: " -/var/log/firewall.log
& ~                     # stops the processing of the information logged in with the previous pattern so that it does not continue to be sent to /var/log/kern.log
__EOF__

cat >> /etc/logrotate.d/ << __EOF__
/var/log/firewall.log
{
rotate 7
daily
size 10M
dateext
MISSING
create 600 root adm
notifempty
compress
delaycompress
postrotate
        /usr/lib/rsyslog/rsyslog-rotate
endscript
}
__EOF__

systemctl restart rsyslog

iptables-save > /tmp/ipt-default.log

iptables -F

iptables -A INPUT -p tcp --dport 8080 --syn -j LOG --log-prefix "[IPTABLES]: "

nc -l 8080
nc -zv localhost 8080

iptables -F INPUT
iptables-restore < /tmp/ipt-default.log
