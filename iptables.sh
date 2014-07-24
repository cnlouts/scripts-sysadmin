
#!/bin/bash

SERVER_IP="xx.xx.xx.xx"

# Flush all rules
iptables -F
iptables -X
# Setting default filter policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
# Allow unlimited traffic on loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT


# ssh in and out
iptables -A INPUT -p tcp -s 0/0 -d $SERVER_IP --sport 513:65535 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -s $SERVER_IP -d 0/0 --sport 22 --dport 513:65535 -m state --state ESTABLISHED -j ACCEPT


# allow www

iptables -A INPUT -p tcp -s 0/0 --sport 1024:65535 -d $SERVER_IP --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -s $SERVER_IP --sport 80 -d 0/0 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

# allow www out
iptables -A OUTPUT -p tcp -s $SERVER_IP --sport 1024:65535 -d 0/0 --dport 80 -m state --state ESTABLISHED -j ACCEPT

# allow 443 

iptables -A INPUT -p tcp -s 0/0 --sport 1024:65535 -d $SERVER_IP --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -s $SERVER_IP --sport 443 -d 0/0 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#allow DNS 



iptables -A INPUT  -p udp -s 0/0 --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p udp -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p tcp -s 0/0 --dport 53 -j ACCEPT


# mysql in

iptables -A INPUT -p tcp -s 162.243.82.60 --sport 1024:65535 -d $SERVER_IP --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -s $SERVER_IP  --sport 3306 -d 162.243.82.60 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT


# make sure nothing comes or goes out of this box
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP
