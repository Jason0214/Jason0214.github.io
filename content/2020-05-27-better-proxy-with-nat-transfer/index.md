---
title: Better Proxy with NAT Transfer
lang: en-US
date: 2020-05-27
tags: [ network ]

---

I have a proxy server that works well, but recently I was quite suffering from the bad networking (very high latency and packet loss) accessing my server.

I have managed to setup another closeby server to do a NAT transfer, which (at least partially) solved the issue.

<!-- more -->

## NAT through iptables
`iptables` is quite handy to use to setup a NAT.
Set up a TCP NAT only takes two rules, while a UDP one may be more complex.
Here is a TCP example:
``` bash
sudo iptables -t nat -A PREROUTING -p tcp --dport $DST_SERVER_PORT -j DNAT --to-destination $DST_SERVER_IP:$DST_SERVER_PORT
sudo iptables -t nat -A POSTROUTING -p tcp -d $DST_SERVER_IP --dport $DST_SERVER_PORT -j SNAT --to-source $LOCAL_PRIVATE_IP
```

Note that:
1. These two rules do not change the `dst port`, make sure to set the listening port of the NAT server the same as the destination server.
2. when tampering the source IP of the packets, make it the NAT server's private IP (LOCAL_PRIVATE_IP) instead of the public. It could be very likely that your rented NAT server is also running behind another NAT.

## Verify NAT works
Running `tcptrack` on your NAT server to check the traffic
``` bash
sudo tcptrack -i eth0
```
If the setting is good, you will see two ESTABLISHED connections for every incoming TCP connection (exactly a NAT will do).

## Add firewall rule to allow only specific IPs 
If you are sure that clients will connect to your NAT server from a static IP or subnet.
It would be better configure it to a firewall rule, so that bandwidth can be saved from transferring random packets in the network.

![1](http://linux-training.be/networking/images/iptables_filter.png)

Note the firewall for NAT goes to FORWARD instead of INPUT.

``` bash
# New chain
sudo iptables -N NAT_WHITE_LIST

# Accept the proxy server
sudo iptables -A NAT_WHITE_LIST --source=$DST_SERVER_IP -j RETURN
# Accept known IPs
sudo iptables -A NAT_WHITE_LIST --source=$ALLOWED_DOMAINS -j RETURN 
# DROP others
sudo iptables -A NAT_WHITE_LIST -j DROP

# Enable chain on FORWARD and NAT port 
sudo iptables -A FORWARD -j NAT_WHITE_LIST
```

### Enable ip forward
``` bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

## Reference
- [http://linux-training.be/networking/ch14.html](http://linux-training.be/networking/ch14.html)
