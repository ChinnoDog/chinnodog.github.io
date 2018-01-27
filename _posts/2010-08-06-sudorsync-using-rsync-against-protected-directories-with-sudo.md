---
title: 'sudorsync: Using rsync Against Protected Directories with sudo'
date: 2010-08-06 11:18:40 -04:00
permalink: "/sudorsync-using-rsync-against-protected-directories-with-sudo/"
categories:
- Ubuntu
---

A frequent scenario I come across when administering Ubuntu servers is that I want to rsync a directory (e.g. a web site) from one server to another but the destination is not writable by my user account. I have permission on the destination via the sudo command but rsync does not have built in support for this. This is rather annoying as I don’t want to enable the root account on the destination just to use rsync and I don’t want to give myself more permissions on the destination since I already have them through sudo. I found some kludge on the web that mostly didn’t work for me so worked out a solution myself. I present the first version of sudorsync, an rsync command that uses sudo! Save this to a file and make it executable and use the same as the rsync command. I’m not an experienced bash programmer so any improvements or suggestions are appreciated.

```bash
#!/bin/bash

#************************************************#
#                   sudorsync                    #
#           written by Stephen Nichols           #
#         Email: ChinnoDog@lonesheep.net         #
#                August 6, 2010                  #
#                                                #
#        rsync using sudo on remote end          #
#************************************************#

BUILD=1        #will write routine to print this with -? later

stty -echo
read -p "[sudorsync] password for remote user: " REMOTEPASS; echo
stty echo

# update the sudo timestamp as part of the remote rsync command
rsync --rsync-path="echo $REMOTEPASS|sudo -S -p $(()) -v;sudo rsync" $*
```
