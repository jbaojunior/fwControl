#!/bin/bash

if [ -z "${1}" ]
then
  configDir='/etc/firewallControl'
else
  configDir="${1}"
fi

if [ "$(id -u)" != 0 ]
then
	echo "Execute this script as root or use sudo"
	exit 5
fi

## Creating the basic config
mkdir -p "${configDir}"/modules

## Creating the basic Rules
# Policy Drop
if [ ! -e "${configDir}"/modules/policy-drop ]
then
  cat <<EOF > "${configDir}"/modules/policy-drop
iptables -t filter -P INPUT DROP
iptables -t filter -P OUTPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
EOF
fi

# Policy Accept
if [ ! -e "${configDir}"/modules/policy-accept ]
then
  cat <<EOF > "${configDir}"/modules/policy-accept
iptables -t filter -P INPUT ACCEPT
iptables -t filter -P OUTPUT ACCEPT
iptables -t filter -P FORWARD ACCEPT
iptables -t filter -A INPUT -p tcp -m state --state established,related -j ACCEPT
iptables -t filter -A INPUT -p udp -m state --state established,related -j ACCEPT
EOF
fi

# Flush the rules
if [ ! -e "${configDir}"/modules/flush ]
then
  cat <<EOF > "${configDir}"/modules/flush
iptables -t filter -F
iptables -t nat -F
EOF
fi

# Clean the stats
if [ ! -e "${configDir}"/modules/clean-stats ]
then
  cat <<EOF > "${configDir}"/modules/clean-stats
iptables -t filter -Z
iptables -t nat -Z
EOF
fi

# Loopback Rules
if [ ! -e "${configDir}"/modules/loopback ]
then
  cat <<EOF > "${configDir}"/modules/loopback
iptables -t filter -A INPUT   -i lo -j ACCEPT
iptables -t filter -A OUTPUT  -o lo -j ACCEPT
EOF
fi

# Drop All
if [ ! -e "${configDir}"/modules/drop-all ]
then
  cat <<EOF > "${configDir}"/modules/drop-all
iptables -t filter -A OUTPUT -j DROP
iptables -t filter -A INPUT -m state --state INVALID -j DROP
iptables -t filter -A INPUT -j DROP
EOF
fi

# Log Rules
if [ ! -e "${configDir}"/modules/drop-log ]
then
  cat <<EOF > "${configDir}"/modules/drop-log
iptables -t filter -A OUTPUT   -j LOG --log-prefix "OUTPUT-DROP: "
iptables -t filter -A INPUT    -j LOG --log-prefix "INPUT-DROP: "
iptables -t filter -A FORWARD  -j LOG --log-prefix "FORWARD-DROP: "
EOF
fi

# Some safety rules
if [ ! -e "${configDir}"/modules/safety ]
then
  cat <<EOF > "${configDir}"/modules/safety
echo "1" > /proc/sys/net/ipv4/tcp_syncookies                            # Protect SYNFLOOD
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts               # Protect ICMP Broadcasting

for i in /proc/sys/net/ipv4/conf/*/rp_filter;                           # Protect Spoof
do
  echo 1 > \${i}
done

iptables -t filter -A INPUT -p icmp --icmp-type 0 -j DROP               # Block Ping
iptables -t filter -A INPUT -p icmp --icmp-type 8 -j DROP               # Block Ping
iptables -t filter -A INPUT -p udp --dport 33435:33525 -j DROP          # Block Traceroute
EOF
fi

if [ ! -e "${configDir}"/modules/web ]
then
  cat <<EOF > "${configDir}"/modules/web
# Web
iptables -t filter -A OUTPUT -p tcp --dport 80   -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 443  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 443  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DNS over TLS (DoT)
iptables -t filter -A OUTPUT -p tcp --dport 853 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DNS
iptables -t filter -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DHCP
iptables -t filter -A OUTPUT -p udp --dport 68 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
EOF
fi

## copy script to path
cp -rf firewallControl /usr/local/bin/
chmod +x /usr/local/bin/firewallControl
cp -rf systemd/firewallControl.service /etc/systemd/system/
systemctl enable firewallControl.service
systemctl start firewallControl.service 
