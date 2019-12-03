---
title: Stop Managing Your Disk Space
date: 2019-11-26 00:00:00 Z
categories:
- Ubuntu
tags:
- security
- grub
---

As a Linux user I never want to see another "out of space" message ever again. Secondary storage space limitations is a problem almost as old as computers themselves. Why are so many of us constantly running into this barrier a half century later? The only insurmountable barrier to disk space issues is the size of the physical storage device. We can't (yet?) waive a magic want and make our physical disks grow in size. For every virtual device layer built on the physical storage there are ways to make the limits dynamic if we choose to use them.

# Contents
* TOC
{:toc}

# Space Management Strategies
There are two basic strategies for managing disk space. You are already using both of them, but one of them is clearly superior.

## The "Big Enough" Strategy
For every device where we know we need some space but don't know how much we try to make the volume large enough for the foreseeable future. Examples include your /boot partition, /root volume, and virtual disks created in your cloud/virtual environment. As most of us know this is what generally leads us to run out of space. We can not predict the future, so try as we might we keep running into barriers we have created for ourselves. When we get close to our limit (or run out) we scramble to enlarge the volume. This is often a time consuming operation that can cause down time while you rectify the problem. Because we can't predict the future this happens repeatedly, wasting our time and energy.

## The Monitor-and-React Strategy
In situations where we have a large storage pool we don't need to estimate sizes. An example of this is managing files on your disk. You do not preallocate space for files based on how big you think they will grow (imagine how painful that would be!), you instead monitor the free space on your storage volume and generally don't worry about it otherwise. You can monitor specific files or directories if they are a concern but other than that your files are free to grow and shrink as needed.

# What is Dynamic Storage?
Dynamic storage allows block devices to grow and shrink as needed, returning the free space back to the underlying device. By doing this every device at every layer of your storage stack can consume as little or as much space as needed provided there is physical space available. In order for this to work every block device we use needs a method by which it can inform the underlying block device which portions of it are unused. This allows space to be returned to the free pool so it can be used by another device or another storage layer. Historically block devices could not communicate this to one another but this is now possible via a couple methods.

## Discard
The discard command was originally used by SSDs to allow you to request that blocks of storage be reset. The reset signal is much more efficient than writing zeros to storage. It also allows the SSD to better manage itself. The discard command is issued by the filesystem, located at the top of the storage tack. This command trickles down through the other block layers (so long as discard is enabled) until it reaches a layer without discard support or until it reaches the physical disk.

## Zero-Based Free Space
Before discard was supported the only way to know that space is unused is that it is filled with zeros. When you delete a file from most filesystems the previously used space is usually not zeroed out. It is left with garbage on it and marked free in the allocation table. In order for the lower level block device to recognize it is free the unused space in the filesystem must be zeroed out. Also, the block device may have a separate out of band reclamation process (sometimes manual) that is used to recognize zero blocks and take them out of service.

# So ... How Big?
There is inevitably some type of size estimation we must do if we are going to allow volumes to grow "without bounds". The reasonable limit to size everything is no longer based on what you will use, but the limits of your physical system. E.g. if you have Hypervisor with 2TB of storage you could make all disks 2TB. Obviously no single disk with reach this limit. Making disks this large isn't necessarily free though, as I will detail down below. Also, if you had a 2PB storage array you probably wouldn't use disks that are 2PB. Use the maximum size you will allow any VM to use.

# About Block Devices
There are a lot of possible block devices in Linux. I'm going to list them below to discuss their quirks. This list does not imply anything about the order you nest these devices. As long as you can inform the layer beneath about free space your scheme will work. The following properties are covered in the table below:

| Attribute | Description |
|-|-|
| Layer | The type of block device |
| Overhead | Dynamic storage is not without overhead. Except in edge cases this overhead is minimal. |
| Free Space Estimation | Technique and/or commands required to monitor the free space. |
| Interface | How the block layer knows which portions of the space within it is free and how it passes this information down to the next block device.

# Dynamic Volumes by Block Device

<style>
table th:first-of-type {
    width: 10%;
}
table th:nth-of-type(2) {
    width: 30%;
}
table th:nth-of-type(3) {
    width: 30%;
}
table th:nth-of-type(4) {
    width: 30%;
}
</style>

| Layer | Overhead | Free Space Estimation | Interface |
|-|-|-|-|
| SSD / HDD[^4] | Hardware Specific | Your hardware is sold as a fixed size. In actuality there are usually spare sectors that are swapped in as hot spares when sectors go bad. Check how close you are by [monitoring SMART](https://www.linuxjournal.com/article/6983) on your drive. | SSD devices support the discard command that is used to erase storage blocks by resetting the underlying chips. Physical hard disks don't implement discard so don't send it! |
| Storage Array / SAN | Vendor Specific | Implementation dependent free space monitor. Ideally loud sirens and lights go off and the storage fairies are summoned since running out of storage could be catastrophic for your connected servers. | Implementation dependent. See virtual disks below. |
| Virtual Disks | Depending on your hypervisor the allocation table for your thin volume may be stored in the same file as the data or a separate one. This file maps used space to sections of your virtual disk file. Expanding your disk comes with the cost of updating your metadata and reading the disk will first require consultation with the allocation table. Check your hypervisor documentation for the resulting performance penalty. | Your hypervisor can tell you how large the virtual disk is relative to its provisioned size. | Some hypervisors accept the discard command for virtual disks in order to allow reclamation of unused sectors. This is the most efficient method since knowledge of free space is able to be passed from the VM to the hypervisor. Those that do not support discard such as VMware ESXi recognize space as free when it is filled with zeros. However, free space reclamation is often not real time and my require manual steps. See your hypervisor documentation. |
| LVM Thin Volumes[^5][^6] | The LVM header occupies 192k at the beginning of physical volume. The LVM thin pool has its own metadata for the storage it contains. Volumes within the thin volumes are "virtual volumes". The LVM thin pool does not need to take up the entire disk if it is configured to be automatically extended[^7]. This may be helpful to limit storage growth if your underlying storage uses zero-based free space. | `lvs` will show you what percentage of your thin pool is consumed. The thin pool | LVM accepts the discard command as a signal that space is free and can be reclaimed. Enabling discard on the LVM physical volume is how you pass the discard command down to the layer below. |
| Filesystems | Most sysadmins know far more about this overhead than any other. See the documentation for your filesystem to learn how much overhead its metadata consumes. In order to recognize free space the filesystem must be mounted with the `discard` option. This is not always efficient since the discard will block the IO operations to the disk. It is often preferable to cron `fstrim -a` in your operating system to do a bulk discard at a regular interval. | `df` command tells you how much free space is available on all mounted filesystems. | Reclamation of space from deleted files is built in as a core design consideration. If you mount the filesystem with the `discard` option then it will pass the discards to the next block device layer. |
| LUKS | The LUKS device itself is not dynamic. It encrypts everything written to it. | Because LUKS encrypts everything 1-to-1

[^1]: Note that older SSDs were sometimes *slower* with the discard command enabled or even worse, unstable. Some SSD manufacturers will recommend you not bother with the discard command.

[^2]: If you are concerned about security you will also realize that the bad blocks are still there when they are decommissioned. You can't normally read them but that doesn't mean someone else can't find a way.

[^3]: There are exceptions to this. Shared disk configurations provide access to multiple VMs but don't multiplex access to the space. They only multiplex access to the virtual storage bus which is not the same. VMs are expected to figure out how to multiplex access to the storage.

[^4]: It is important to note that the hardware device has a partition table on it and that this partition table is the lowest level allocation table visible on the system using it. The partition table typically allocates space on the entire disk and is _not_ dynamic. Use the minimum number of partitions required (1 with an MSDOS layout, 2 on an GPT layout) and you will only need to worry about enlarging it when the disk is enlarged.

[^5]: Thin volumes is a recent addition to LVM. Traditional volumes on LVM are not dynamic but do still allow you to pass the discard command from the filesystem to the physical volume.

[^6]: Grub does not currently support booting from a thin volume. If your /boot volume is on LVM it must be a standard volume and not part of the thin pool.

[^7]: See `lvmthin(7)``
