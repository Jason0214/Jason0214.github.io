---
title: Raspberry Pi as a Wifi Access Point
lang: en-US
date: 2020-07-14
tags: [ embedded system ]
---

Make Raspberry Pi 4 an access point -- and further a transparent proxy. 

<!-- more -->

## Setup Raspberry Pi 4 headlessly
I bought a Raspberry Pi 4 recently.
In the first experience,
I am a little surprised that Pi can not be easily setup in a headless way.
Probably Pi 4 is so powerful that can speak "just use it as a PC",
which might be the reason that documentations just tell you to connect a display, a keyboard and a mouse to set it up.

Anyway, I found a relatively easy way to setup Pi it by searching online.
The idea is to connect Pi to your wireless network in boot up.
The post [headless-raspberry-pi-4-ssh-wifi-setup](https://desertbot.io/blog/headless-raspberry-pi-4-ssh-wifi-setup) gives instructions to write Wifi config to the OS image, then put the image on a SD-card and boot Pi from it.
Once boot up, hopefully Pi is automatically connected to Wifi and you can access it using `ssh`.

## Requirements 
Ensure the WLAN support "AP" mode by checking
``` bash
$ iw list
```

Raspberry Pi 4 has it supported.

Install the following applications before you start, as you may lose internet connection in configuring your WLAN.
``` bash
sudo apt instal hostapd # For access point
sudo apt instal dnsmasq # For DHCP and DNS service
```

## Choose a WLAN interface
To be an access point, Pi needs a wireless LAN interface to be connected to by clients, while itself also needs access to the network.

1. You can connect Pi to ethernet (Pi 4 has an ethernet port) and use Pi's builtin WLAN to be the access point.
2. You can connect Pi to wifi with the builtin WLAN and install another WLAN interface (e.g. a wifi dongle) to be the access point.   
3. You can use one physical WLAN to both connect to a wifi as a client and act as the access point simultaneously. Check out [VAPs](https://superuser.com/questions/155795/can-a-linux-machine-act-as-both-a-wireless-client-and-access-point-simultaneousl), [Simultaneously AP and managed Wifi](https://blog.thewalr.us/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/), and [rpi-wifi](https://github.com/lukicdarkoo/rpi-wifi), though it has some limitations and seems a bit more complicated to setup than other alternatives.

I tried the second approach with a TL-WN726N external wireless card, but I can not find a Linux driver for it, so I failed to get it working (see [Appendix](## Appendix: Install driver for a wifi dongle (TL-WN726N))).
Then I end up using the builtin WLAN on Pi as the access point.

## Network mode
Providing internet access in AP mode could be done using either [Bridge](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-bridged.md) or [NAT](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md).

The following content is my step by step **NAT** setting up, I consider it a good complement to the official documentation linked above. I also extend my Pi to be a transparent proxy, which is pretty straight-forward once you get the AP working.

## Release wireless interface from network manager
To set up an access point on the builtin WLAN, WLAN needs to be released from being used as a wireless client.
`wpa_supplicant` is the default network manager on raspberry Pi.
It is the one being used to in the post I linked to booting up Pi with a wireless connection.
Here releasing WLAN from `wpa_supplicant`, which configures the WLAN to be the wireless client, and let an access point service manage it.

Add the following two lines to `/etc/dhcpcd.conf`,
`dhcpcd` is the default DHCP client on raspberry pi, the configuration change sets a static IP address to `wlan0` and releases it from the network manager.
``` bash
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant # Release from ..
```

## Run hostapd
Next step, enable access point service on the WLAN.
`hostapd` is a daemon to run an access point service, which will be used to configure `wlan0`.
After that your wireless network will be visible by client devices and `hostapd` will manage
    - the credentials
    - the protocols
    - the encryption
    - ...

Refer to [Arch Software Access Point](https://wiki.archlinux.org/index.php/software_access_point) and [Linux Wireless Documentation](https://wireless.wiki.kernel.org/en/users/documentation/hostapd) for configurations of `hostapd`.
Check the documentations and you will find there aren't many you need to change.
Configure the `interface`, `channel`, `ssid`, `wpa_passphrase`, `auth_algs`, `*_pairwise`, others can just be left as the defaults.

Make sure to check the most recent documents/posts to select the appropriate key exchange protocols through `*_pairwise` to have the right security level desired.

Here is one example:
``` bash
...
# Operation mode (a = IEEE 802.11a (5 GHz), b = IEEE 802.11b (2.4 GHz)
hw_mode=g
# Channel number
channel=7
# Maximum number of stations allowed
max_num_sta=4

macaddr_acl=0
ignore_broadcast_ssid=0
# Bit field: 1=wpa, 2=wep, 3=both
auth_algs=1
# Bit field: bit0 = WPA, bit1 = WPA2
wpa=2
# Set of accepted key management algorithms
wpa_key_mgmt=WPA-PSK
#rsn_pairwise=CCMP
wpa_pairwise=CCMP
...
```

You may want to use the best quality `channel` in your local area, which needs some steps to find out, as it is affected by ther wireless devices/routers around you as wel as the law in your country.
If you are using MacOS, you can scan the local network using [Wireless Diagnostics](https://www.chriswrites.com/boosting-your-wi-fi-time-to-change-the-channel/)
On Linux, try [iwlist](https://linux.die.net/man/8/iwlist)

## DHCP service
Set up DHCP services for IP ditribution to clients. Here doing it use `dnsmasq`.

Add following lines to change `/etc/dnsmasq.conf`
``` bash
interface=wlan0 # Listening interface
dhcp-range=192.168.4.2,192.168.4.5,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/gw.wlan/192.168.4.1
                # Alias for this router
```

Note that the config only allows 4 IPs to be allocated, change the config if having more client devices.

## Enable packet routing
In order to get client devices access to internet, packet received at `wlan0` need to be forwarded to `eth0`.
``` bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
```

For correctly routing (another word for IP forward), a masquerade rule is required to replace the `src`/`dst` address in packets' IP frame head to the IP address of Pi, in both sending and receiving packets from `eth0`.
``` bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

## Transparent proxy
A transparent proxy is basically a proxy that runs inside the router, so that it is invisible (transparent) to the router client devices.
Shadowsocks's `ss-redir` is a lightweight transparant proxy client that can be easily set up. 
`ss-redir` listens at a local port and sends the traffic received on th local port to the shadowsocks server (through `eth0`).

Create firewall rules to route traffic received from `wlan0` to the local port of `ss-redir`.
Refer to [shadowsocks](https://github.com/shadowsocks/shadowsocks-libev#transparent-proxy) for configurations.

## DNS service
On Linux, DNS is provided in some fixed C library which parses `resolv.conf`.
However the configuration file `resolv.conf` can be managed by a lot of applications.
In our case, `dnsmasq` will be one of them and it is necessary for it to exclusively manage DNS resolving.
Check `/etc/resolv.conf`, ensure `nameserver` is set to `127.0.0.1`, so that all the DNS query will be handled by `dnsmasq`.

Run `dig` on one of the client devices to verify that DNS is working properly.
``` bash
sudo apt install dnsutils
dig www.google.com
```

You might also want to set a DNS proxy using `ss-tunnel`, if so `dig` with custom host and port.
``` bash
dig @127.0.0.1 -p 1086 www.google.com # Replace 1086 with your local `ss-tunnel` port.
```
If the DNS proxy is not working, the top common reasons might be
1. UDP relay is not enabled on your shadowsocks server (missing the `-u` argument)
2. UDP traffic is blocked by your VPS provider, check the firewall rules of your VPS. 


## Reference
- [https://wiki.archlinux.org/index.php/software_access_point](https://wiki.archlinux.org/index.php/software_access_point)
- [https://wireless.wiki.kernel.org/en/users/documentation/hostapd](https://wireless.wiki.kernel.org/en/users/documentation/hostapd)
- [https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point/](https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point)
- [https://unix.stackexchange.com/questions/14056/what-is-kernel-ip-forwarding](https://unix.stackexchange.com/questions/14056/what-is-kernel-ip-forwarding)
- [https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md)
- [https://www.raspberrypi.org/documentation/configuration/wireless/access-point-bridged.md](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-bridged.md)
- [http://hbprotoss.github.io/post/da-jian-zhi-neng-fan-qiang-lu-you-qi/](http://hbprotoss.github.io/post/da-jian-zhi-neng-fan-qiang-lu-you-qi/)
- [https://unix.stackexchange.com/questions/494324/how-to-setup-dns-manually-on-linux](https://unix.stackexchange.com/questions/494324/how-to-setup-dns-manually-on-linux)

## Appendix: Install driver for a wifi dongle (TL-WN726N)
I have tried to make the access point using a wifi dongle.

I got a wifi dongle from TP-Link, the TL-WN726N.
However, I failed to get it to work on Raspberry Pi because there is no available linux driver for it.

I almost get the end of configuring the dongle, and the steps are listed below.

1. Insert wifi dongle and show usb device information.
``` bash
$ lsusb
```
For example, the device from 'Realtek Semiconductor Corp' is my wifi dongle.
```
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 0bda:1a2b Realtek Semiconductor Corp.
Bus 001 Device 002: ID 2109:3431 VIA Labs, Inc. Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

2. Check kernel log
``` bash
$ dmesg
```
Dongle recoginized, though as a usb storage device (see below).
```
[159348.249956] usb 1-1.3: new high-speed USB device number 67 using xhci_hcd
[159348.380395] usb 1-1.3: New USB device found, idVendor=0bda, idProduct=1a2b, bcdDevice= 2.00
[159348.380410] usb 1-1.3: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[159348.380423] usb 1-1.3: Product: DISK
[159348.380435] usb 1-1.3: Manufacturer: Realtek
[159348.384264] usb-storage 1-1.3:1.0: USB Mass Storage device detected
[159348.384669] scsi host0: usb-storage 1-1.3:1.0
```

3. If the driver is onboard in the dongle, it may first get recognized as an usb storage device.
In that case, you need to manually switch its usb mode with [usb_modeswitch](https://linux.die.net/man/1/usb_modeswitch)
``` bash
$ sudo usb_modeswitch -KW -v 0bda -p 1a2b
```

Once done switching, check usb device information again.
``` bash
$ lsusb
```
Note that the product ID changes from `1a2b` to `b711`.
```
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 066: ID 0bda:b711 Realtek Semiconductor Corp.
Bus 001 Device 002: ID 2109:3431 VIA Labs, Inc. Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

4. For dongle bought online, most likely it missing its Linux driver. Then you may try to find one on the internet.
According to [https://devicehunt.com/view/type/usb/vendor/0BDA/device/B711](https://devicehunt.com/view/type/usb/vendor/0BDA/device/B711), the device `0bda:b711` is RTL8188GU 802.11n WLAN Adapter (After Modeswitch)  

I looked up for driver for `RTL8188GU` online, the closest one I found is [lwfinger/rtl8188gu](https://github.com/lwfinger/rtl8188gu).
Though it has the name `rtl8188gu`, the author mentioned  in the issues (and (I can also tell it from kernel log) that this merely a modification of `rtl8710bu` that he thinks might work on `rtl8188gu`.

Looking at the [issues](https://github.com/lwfinger/rtl8188gu/issues/2), several people tried this driver but all failed and reached the conclusion that there is no public available linux driver for `rtl8188gu` for now.

I tried to compile and install it anyway, to my Raspberry Pi, but it is not working as expected.

For driver compiling, kernel headers is necessary.
``` bash
$ sudo apt install raspberrypi-kernel-headers
$ git clone https://github.com/lwfinger/rtl8188gu && cd rtl8188gu && ARCH=arm make all && sudo make install && cd -
```

The compilation is good and the driver recognizes my device as a WLAN, but it fails on verifying some checksums.
``` bash
$ dmesg

...
[137684.292802] RTW: Clear the 0x40000138[5] to prevent CM4 Suspend! 0x40000138 = 0x0
[137684.293161] RTW: rtl8710b_FirmwareDownload fw: FW_NIC, size: 23750
[137684.293167] RTW: rtl8710b_FirmwareDownload: fw_ver=10 fw_subver=0000 sig=0x10b1, Month=09, Date=15, Hour=14, Minute=50
[137684.293210] RTW: rtl8710b_FirmwareDownload by IO write!
[137684.563646] RTW: polling_fwdl_chksum: Checksum report OK! (1, 0ms), REG_MCUFWDL:0x01050105
[137684.563651] RTW: rtl8710b_FirmwareDownload: download FW count:1
[137684.760545] ***** value_to_check 0x82, value_expected 0xc6
[137684.760552] RTW: _FWFreeToGo: Polling FW ready Fail! (4319, 200ms), REG_MCUFWDL:0x01050182
[137684.760639] RTW: DUMP REG 0x90=0x1000101
[137684.760643] RTW: ERROR Dump FW page 0x1000 ~ 0x10FF :0
```

I stuck here.

## AP and Client mode simultaneously
TODO: [https://blog.thewalr.us/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/](https://blog.thewalr.us/2017/09/26/raspberry-pi-zero-w-simultaneous-ap-and-managed-mode-wifi/)



