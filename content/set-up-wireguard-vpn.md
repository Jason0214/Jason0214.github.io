---
title: Set Up Wireguard VPN Server
lang: en-US
date: 2022-02-13
tags: [ network ]
---

Wireguard is a VPN protocol, which has an implementation presents in the Linux kernel.
This post records my first time experience setting up a Wireguard VPN for my heterogeneous devices (Macbook, iphone, etc.)
<!-- more -->

### Motivation

There are a lot of things of Wireguard that I would consider very interesting.
Such as
- [formal verification](https://www.wireguard.com/formal-verification/) that the protocol that has gone through,
- [implementation](https://git.zx2c4.com/wireguard-linux) inside Linux kernel,
- [clients](https://github.com/WireGuard) are available for different platforms with community efforts,
etc.

These facts give me a good confidence on its security and performance.
And here goes this post, a written down of my first time experience to set up a working Wireguard VPN service.

### The server
I used a VM instance from one of those big cloud service providers to build my Wireguard server.
I call it a server because I have some presets in my mind about how I would use the Wireguard guard for,
I would like to re-route all the network traffic of some of my mobile devices to a remote server.
Thus, the remote server works more like a "server".

However, the Wireguard protocol and its configuration are more Peer-to-Peer-ish.
It can be more flexible than the server-client model I am going to describe below.

I used a Ubuntu 20.04 LTS for my server.
Wireguard implementation is presented in Linux kernel starting from 5.6.
If you are using a kernel older than 5.6, you need to install the manually install Wireguard kernel driver through "apt install wireguard-dkms", otherwise you are good.
In both case, you will need some userspace utilities through "apt install wireguard".

#### Key pairs
Wireguard peers authenticates use public and private key.
Every Wireguard peer (either server or client in my case) generates a public and private key pair. 
The public key will be given to other peers for authentication and access control.
[This DigitalOcean guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04#step-1-installing-wireguard-and-generating-a-key-pair)
gives a good instruction on to generate key pairs.

#### Choose IP ranges
The above DO Wireguard guide also has a well written section on how to choose both IPv4 and IPv6 for VPNs.

In my case, I choose the subnet 10.8.0.1/24.

#### Create ip interface and routes
```
ip link add dev wg0 type wireguard
```
This command creates an interface "wg0" with type `wireguard`.

```
ip address add dev wg0 10.8.0.1/24
```
This command assigns IP protocol and address to the interface "wg0".
It is essential for the server to know that
it needs to send traffic with destination "10.8.0.1/24" to interface "wg0".
You can use `ip route` to verify its effect.

```
ip link set up dev wg0
```
Activate the "wg0" interface. Now, you can see it with `ifconfig`

#### Create configuration
Edit "/etc/wireguard/wg0.conf" to the following content
``` nginx
[Interface]
ListenPort = ... 
PrivateKey = ... 

[Peer]
PublicKey = ... # The public key of peer(client)
AllowedIPs = 10.8.0.2 # I will assign this IP to client in the following sections.

#[Peer]
# More peers ...
```

Most of the fields here are trivial to fill.
However, the "AllowedIPs" is worth some explanation.
This fields denotes what traffic the server is going to send to the client.
Since I am building a server-client model, the server only needs send client the traffic aiming for the client, thus the field is the client's IP.
If you are setting up a topology that allows some kind of broadcast within the subnet, then "10.8.0.0/24" would make more sense.

Also, note that "ListenPort" is the used by the kernel implementation to watch for UDP traffic.
Not TCP it is using, and not from a user space process, so don't expect to find the port being opened on those monitoring tool.
Though, you will see ingress and egress traffic on the port when the VPN is on later.

```
wg setconf wg0 /etc/wireguard/wg0.conf
```
This command applies the above configurations to "wg0" interface.
You can use "wg show" to 

#### Firewall rules
```
iptables -A FORWARD -i wg0 -o <ethernet_interface> -j ACCEPT
iptables -t nat -I POSTROUTING -o <ethernet_interface> -j MASQUERADE
```
These two rules forwards traffics from interface "wg0" to the actual ethernet interface.
Refer to [DO Wireguard guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04#step-5-configuring-the-wireguard-server-s-firewall) on the explanation and how to get the ethernet interface.

``` bash
apt install iptables-persistent
```
To make those rules persistent to reboot.

#### Setup systemctl service
The userspace Wireguard tool comes with a nice script `wg-quick` and a service `/lib/systemd/system/wg-quick@.service`.
With the help of them, the above created "wg0.conf" can be easily turned into a systemctl service.

Before creating the service for "wg0", we would want to de-active what we have done to it.
Otherwise, when service starts, some ip settings may duplicate and fail.

``` bash
wg-quick down wg0 # The reverse is "wg-quick up wg0"
```

``` bash
systemctl enable wg-quick@wg0 # maps to /etc/wireguard/wg0.conf
systemctl start wg-quick@wg0
```

### The client

Setup client is very similar to dealing with the server.
Anyway from the perspective of the protocol, both of them are just Wireguard peers.

I used the Wireguard client from Apple App Store.
It turns out that I only need to provide a configuration file, other parts are taken care of by the application itself.

The client configuration looks like this:
``` nginx
[Interface]
PrivateKey = ...
Address = 10.8.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = ...
AllowedIPs = 0.0.0.0/0
Endpoint = <server_ip>:<server_listen_port>
PersistentKeepalive = 25
```
Simply provides "DNS" in the "interface" would allow all the DNS traffic to go through the VPN.
For the "AllowedIPS" field, I fill it with wild card because I want to secure all the traffic.
Also some are saying "PersistentKeepalive" is important if your peers are behind stateful firewall.

### Debugging
Because the Wireguard implementation resides in the Linux kernel, it almost leaves no trace in the user space.
The only approach let Wireguard spit out some logs is through the kernel dynamic debugging.

```
echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control
```
However, on my VM, I found privilege is missing even I execute the command from "root" user, which means the `debugfs` is not accessible at all.
So, do expect this to happen, if you are also running VMs from service providers.
Fortunately, compared to other alternative technologies, I found Wireguard relatively easier to set up.

Thanks for the reading.

## Reference
- [https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04)
- [https://www.wireguard.com/quickstart/](https://www.wireguard.com/quickstart/)
