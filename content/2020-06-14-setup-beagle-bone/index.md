---
title: Setup Beagle Bone
lang: en-US
date: 2020-06-14
tags: [ embedded system ]

---

Instructions on setting up development environment on Beagle Bone, in case I forget it again.
<!-- more -->

### Check USB connection

First, verify the USB connection
``` bash
$ usb-devices
```

If it's good, something similar to the following will show up
``` log
T:  Bus=01 Lev=01 Prnt=01 Port=01 Cnt=02 Dev#=  4 Spd=12  MxCh= 0
D:  Ver= 1.10 Cls=ef(misc ) Sub=02 Prot=01 MxPS=64 #Cfgs=  1
P:  Vendor=1d6b ProdID=0104 Rev=04.04
S:  Manufacturer=Seeed
S:  Product=BeagleBoneGreen
```

Alternatively you can check the kernel log
``` bash
$ dmesg | grep usb
```

Example result:
``` log
[  841.388142] usb 1-2: New USB device found, idVendor=1d6b, idProduct=0104
[  841.388144] usb 1-2: New USB device strings: Mfr=3, Product=4, SerialNumber=5
[  841.388146] usb 1-2: Product: BeagleBoneGreen
[  841.388147] usb 1-2: Manufacturer: Seeed
[  841.388148] usb 1-2: SerialNumber: BBG217071901
```

### Serial Port over USB

Find the `tty` corresponding to Serial over USB by checking kernel log
``` bash
$ dmesg | grep tty
```

e.g. found `ttyACM0`
``` log
[    5.901768] cdc_acm 1-2:1.2: ttyACM0: USB ACM device
```

Connect through Serial Port
``` bash
$ sudo screen /dev/ttyACM0 115200
```

Frequently used Serial instructions:
- Show help: `Control a + (no control) ?`
- Exit: `Control a + (no control) \
`


### Ethernet over USB

Execute `ifconfig` on both Beagle Bone and your Host device to check the IPs and interfaces of Ethernet over USB. 

Seems by default, Beagle Bone and Host are under the subnet `192.168.7.0/24`,
with Beagle Bone having IP address `192.168.7.2` and Host having IP address `192.168.7.1`.

### Route Beagle Bone network traffic on Host 

#### On Beagle Bone

Route all traffic to Host (IP `192.168.7.1`)
``` bash
$ sudo ip route add default via 192.168.7.1
```

#### On Host
Find `<Beagle Bone interface>` and `<Host network interface>` through `ifconfig`

Enable IP layer forward
``` bash
$ sudo sysctl -w net.ipv4.ip_forward=1
```

Add NAT rule
``` bash
$ sudo iptables -A FORWARD --in-interface <Beagle Bone interface> -j ACCEPT
$ sudo iptables -t nat -A POSTROUTING --out-interface <Host network interface> -j MASQUERADE
```

### DNS server
Prepend DNS server address to `resolv.conf`
```
$ sudo sed -i '1inameserver 8.8.8.8' /etc/resolv.conf
```

