---
title: Install Ubuntu with Full Disk Encryption and Encrypted Boot
date: 2018-10-31 00:00:00 Z
categories:
- Ubuntu
tags:
- security
- grub
---

These are directions for installing Ubuntu with <code>/boot</code> encrypted and stored on LVM. We accomplish this feat by using the LUKS support in grub to decrypt the partitions during the first stage of the boot process. Since grub can also read LVM that means that <code>/boot</code> can be stored on an LVM logical volume. Info collected from... well, I don't remember anymore. Sorry, Internet. So boot up to the Ubuntu LiveCD and let's begin.

# Contents
* TOC
{:toc}

# Why Do I Want This?
* Security - While this won't prevent an evil maid attack against grub2 it will make it more difficult. Without Linux kernel exposed the only data left to hack offline is grub itself.
* You can choose to finally stop having to deal with those annoying messages that /boot is full when you upgrade your kernel. Without LUKS support in grub you must create a separate <code>/boot</code> partition that can be read before the disk is decrypted.

# Assumptions
* System uses EFI boot. This is the default on most modern computers.
* There is one SSD (sda) and HDD (sdb) where the former is an SSD and the latter is an HDD. Obviously your configuration may be different. This is a common setup though.
* The SSD erase block size (EBS) is 2mb. This is different on every SSD. Discovering your EBS is out of scope here; maybe good for a future post. I suggest looking up your EBS on the Internet. If in doubt 2mb is a reasonably safe number. Estimating too high is better than too low.
* The hard disk has 4k clusters. This is true of most modern hard disks. Accomodating this will have little to no impact on performance if you have an older disk with 512b clusters.
* You  are not using btrfs as your filesystem. Add the subvol option to the mount commands if you are. The default subvol for the root volume is <code>@</code> and the default subvol for home is <code>@home</code>.
* You want to manage encrypted block device with LVM. Yes, I know that btrfs on LVM is generally considered bad. Theoretically any disk layout supported by grub should result in a bootable system.
* You are running the commands below as root. Run <code>sudo su</code> to begin.

## Prepare The Disk(s)
First we will set up the disks. You can deviate from this disk layout. In the end grub will detect whatever layout you choose and create a boot configuration that works with it.

```bash
# log in as root
sudo su

# Write new disk labels. ANY EXISTING DATA WILL BE LOST.
parted /dev/vda mklabel gpt
parted /dev/vdb mklabel gpt

# Create an EFI partition. I can't find agreement on the recommended size but
#  one source said it could not be smaller than 160mb so lets go with that.
parted /dev/vda mkpart pri 2MiB 164MiB
parted /dev/vda set 1 boot on
mkfs.vfat -F 32 /dev/vda1

# Create data partitions
parted /dev/vda mkpart pri 164MiB 100%
parted /dev/vdb mkpart pri 1MiB 100%

# Set the disk password to something secure
pw="password"

# Encrypt the partitions. luks has a default offset of 2mb. If your partitions
# are aligned with your EBS in the preivous step then this should be fine.
echo -n "$pw" | cryptsetup luksFormat /dev/vda2
echo -n "$pw" | cryptsetup luksFormat /dev/vdb1

# Open the encrypted partitions
echo "$pw" | cryptsetup open /dev/vda2 cryptssd
echo "$pw" | cryptsetup open /dev/vdb1 crypthdd

# Format encrypted block devices as LVM
pvcreate /dev/mapper/cryptssd --dataalignment 2mb
pvcreate /dev/mapper/crypthdd --dataalignment 4kb

# Create the volume group. I use a single VG; you don't have to.
vgcreate vg /dev/mapper/cryptssd /dev/mapper/crypthdd

# Create volumes for the OS now because the installer won't let you.
lvcreate -n root -L 10G vg /dev/mapper/cryptssd
lvcreate -n swap -L 2G vg /dev/mapper/crypthdd
lvcreate -n home -L 20G vg /dev/mapper/crypthdd
```

## Launch Ubuntu Installer

```bash
# Updating ubiquity unnecessary on latest version of Ubuntu but can't hurt.
apt-get update
apt-get install -y ubiquity

# Launch Ubuntu installer but don't install grub
ubiquity -b
```

# Install Ubuntu
We ran ubiquity without bootloader installation because it will expect a separate unencrypted partition for /boot and crash as a result. This is unfortunate as grub has supported encrypted disks for some time. When the installer asks you how to partition the disk be sure to select the manual option. Set sda1 as the EFI partition and format and mount the logical volumes that were created. I'll assume you can handle the rest of the installation options. At the end click "continue testing". We can't reboot yet, we don't have a bootloader!

# Chroot Into the New Installation

```bash
# Mount your filesystems to /target
mount /dev/vg/root /target
mount /dev/vg/home /target/home
mount /dev/vda1 /target/boot/efi

# bind mount important stuff to /target (including dns file)
for fs in proc sys dev dev/pts run etc/resolv.conf; do mount --bind /$fs /target/$fs; done

# Chroot into our new Ubuntu installation
chroot /target
```

# Add LUKS Support During Grub Boot
```bash
# Make the following two modifications to the grub configuration:
# GRUB_ENABLE_CRYPTODISK="y"
# GRUB_CMDLINE_LINUX="cryptodevice=/dev/vda2:cryptssd"
vi /etc/default/grub
update-grub

# Install grub for your architecture. (DO NOT INSTALL SIGNED VERSION)
apt-get install -y grub-efi-amd64
```

# Add LUKS Support during Linux Boot
```bash
# We're going to need a second way to decrypt our LUKS volumes if it is going
#  to be done autmatically at boot. We'll create and add a key file.
dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
chmod 0000 /crypto_keyfile.bin
echo "$pw" | cryptsetup luksAddKey /dev/vda2 /crypto_keyfile.bin
echo "$pw" | cryptsetup luksAddKey /dev/vdb1 /crypto_keyfile.bin

# Get the UUIDs of the LUKS volumes
blkid | grep crypto_LUKS

# Add the following lines to /etc/crypttab
#  cryptssd UUID=### /crypto_keyfile.bin luks,keyscript=/bin/cat
#  crypthdd UUID=### /crypto_keyfile.bin luks,keyscript=/bin/cat
# Here, I automated it for you:
cat >/etc/crypttab << EOF
$( for d in cryptssd crypthdd; do cryptsetup status $d | grep device \
| cut -f 2 -d : | xargs -I % blkid % | cut -f 2 -d ' ' | perl -pe 's/"//g' \
| xargs -I % echo $d % /crypto_keyfile.bin luks,keyscript=/bin/cat; done )
EOF

# Now it will use the key file but it won't do us much good since it isn't
#  available until after volume decryption. It must be added to initramfs
cat > /etc/initramfs-tools/hooks/crypto_keyfile << EOF
#!/bin/sh
cp /crypto_keyfile.bin "\${DESTDIR}"
EOF
chmod +x /etc/initramfs-tools/hooks/crypto_keyfile

# Now just rebuilt the initramfs!
update-initramfs -c -k all

# Reboot time
exit
reboot
```

# First boot
If all has gone well you can now reboot and you will be prompted for a password. The password will be used to unlock your LUKS volumes and away you go! You might also see "press any key to continue..." after you do this but this is a red herring. You do not need to press any keys.

# Notes
* I tested these directions on Ubuntu 18.04 but originally used them on an older version
* Currently do-release-upgrade will cause grub-efi-amd64-signed to be installed which will break this configuration. If you upgrade Ubuntu then remove the package before you reboot and use dpkg to reinstall grub-efi-amd64.
* Attempts to use these directions with the LUKS2 format may result in failure. This format became available in some distributions after this article was originally written and as usual the other components will need to catch up. Keep your eyes peeled on [grub bug #55093](https://savannah.gnu.org/bugs/?55093) for more info. Thanks to
Jérémie Liénard for finding this.
