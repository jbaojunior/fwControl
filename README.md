## FWCONTROL

fwControl is a simple shell script that I used to help a manager some iptables rules in my desktop.

It is not advanced. I build to help a load and unload some rules while I work and do some tests.

The ideia is have some default rules and load others rules very easy.

The default policy is DROP and it is used just in table filter. I control all my output and block all my input.

The default directory is `/etc/fwControl`. This can be change using the parameter `-C` together with shell script.

The modules that can be used are inside directory `etc/fwControl/modules`.  You can create your own file rules and put inside this directory. To load automatically when service started use the file `modules.fw` put the modules name in each line. This file should be create in the `etc/fwControl`.

The rules default are:

Module: loopback
```
iptables -t filter -A INPUT   -i lo -j ACCEPT
iptables -t filter -A OUTPUT  -o lo -j ACCEPT
```

Module: policy-drop
```
iptables -t filter -P INPUT DROP
iptables -t filter -P OUTPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Module: web
```
# Web
iptables -t filter -A OUTPUT -p tcp --dport 80   -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 443  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 443  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DNS over TLS (DoT)
iptables -t filter -A OUTPUT -p tcp --dport 853 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DNS
iptables -t filter -A OUTPUT -p tcp --dport x853 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# DHCP
iptables -t filter -A OUTPUT -p udp --dport 68 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
```

Module: safety
```
echo "1" > /proc/sys/net/ipv4/tcp_syncookies                            # Protect SYNFLOOD
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts               # Protect ICMP Broadcasting

for i in /proc/sys/net/ipv4/conf/*/rp_filter;                           # Evicted Spoofing 
do
  echo 1 > ${i}
done

iptables -t filter -A INPUT -p icmp --icmp-type 0 -j DROP               # Block PING
iptables -t filter -A INPUT -p icmp --icmp-type 8 -j DROP               # Block PING
iptables -t filter -A INPUT -p udp --dport 33435:33525 -j DROP          # Block TRACEROUTE
```

Module: drop-log
``` 
iptables -t filter -A OUTPUT   -j LOG --log-prefix "OUTPUT-DROP: "
iptables -t filter -A INPUT    -j LOG --log-prefix "INPUT-DROP: "
iptables -t filter -A FORWARD  -j LOG --log-prefix "FORWARD-DROP: "
```

Module: drop-all
```
iptables -t filter -A OUTPUT -j DROP
iptables -t filter -A INPUT -m state --state INVALID -j DROP
iptables -t filter -A INPUT -j DROP
```


The commands need to be execute as root and work with sudo command.

The options are:
  - -m module_name
  <br>&emsp;Name of module that will be used to configure iptables
  
  - -z
    <br>&emsp;Clean all iptables statistics

  - -a
    <br>&emsp;Flush all rules and set ACCEPT as default action to all tables

  - -c module_file 
    <br>&emsp;File with modules name to be load. The format is one module per line. The default is ${CONFIG_DIRECTORY}/modules.fw

  - -C config_directory
    <br>&emsp;Modules files directory. Default is /etc/fwControl

  - -l 
    <br>&emsp;List all modules can be used"

  - -p module_name 
    <br>&emsp;Print the rules of modules. The parameter all will print the content of all modules

  - -h
    <br>&emsp;Show this help

### INSTALL
Clone this project and execute `./installfwControl.sh` as root.
oil
