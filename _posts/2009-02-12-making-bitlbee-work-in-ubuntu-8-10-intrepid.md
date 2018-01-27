---
title: Making bitlbee Work in Ubuntu 8.10 (Intrepid)
date: 2009-02-12 21:16:22 -05:00
permalink: "/making-bitlbee-work-in-ubuntu-8-10-intrepid/"
categories:
- Ubuntu
---

[Bitlbee](http://web.archive.org/web/20100730002710/http://www.bitlbee.org/) is a IRC proxy that allows you to connect to instant messenger services using an IRC client.  It emulates an IRC server so you can connect to it from your favorite IRC client and then plug in your account information.  You can install it on a server for shared use or install it on a workstation to connect to locally.  Unfortunately, it doesn’t work out of the box in Ubuntu.  Here is what I did to install it.

```bash
# Install bitlbee (duh).
sudo apt-get install bitlbee

# Install xinetd if you don’t already have it.
sudo apt-get install xinetd

# Now we need to copy bitlbee.xinetd into /etc/xinetd.d per the instructions.
# Oops, we don’t seem to have that.  Make a temporary directory and download
# the source to get it.
cd ~
mkdir bitlbeesrc
cd bitlbeesrc
sudo apt-get source bitlbee
cd bitlbee-1.2.3/doc
sudo cp bitlbee.xinetd /etc/xinetd.d

# (you are done with the source)
cd ~
rm -rf bitlbeesrc
```

The /etc/xinetd.d/bitlbee.xinetd we just copied still has its default settings. Open it up in nano or your favorite editor and set “user = bitlbee” and “server = /usr/sbin/bitlbee”.

```bash
# Restart xinetd.
sudo /etc/init.d/xinetd restart

# Almost done. If you connected to bitlbee now you would get permissions errors.
sudo chmod 777 /etc/bitlbee/bitlbee.conf
sudo chmod 777 /var/lib/bitlbee
```

I would like to point out here that I KNOW that you don’t want to be setting 777 permissions everywhere. Lock this down later if you are concerned. At this point everything is ready.  Connect to localhost on the default IRC port (6667).  Proceed with the [quickstart guide](http://web.archive.org/web/20100730002710/http://princessleia.com/bitlbee.php) written by [pleia2](http://web.archive.org/web/20100730002710/http://princessleia.com/) to add accounts.
