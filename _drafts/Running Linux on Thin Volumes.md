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

## Preallocation
We have a bunch of block devices but we don't know how big to make them. So we come up with an approximation for how large they will need to be for the foreseeable future and we use those values during initial setup. Examples include setting up your partition table, sizing your /root and /home volumes, and selecting the initial size of your virtual disk. The problem is, we can not see the future. We will keep running into these artificial barriers we have created for ourselves. And when we do, it stop us in our tracks from moving forward until we have rectified the situation by increasing the amount of available space. So then we must scramble to raise the storage limit. This can be a time consuming operation and can block everything and everyone while you rectify the problem. This happens repeatedly, wasting our time and energy.

## Monitoring
In other situations we are comfortable assuming that that storage is unlimited and consuming it as needed. The most familiar example of this is managing files on your disk. You do not preallocate space for files based on how big you think they will grow (imagine how painful that would be!), you instead monitor the free space on your file system and generally don't worry about it otherwise. You assume that the storage volume is big enough and do not check the size every time you perform a write operation. If you are concerned about the size of certain files or directories there are additional mechanisms you can use to limit their size to safe values.

# What is Dynamic Storage?
Dynamic storage allows allocated pools to be resized as needed and always uses the monitoring strategy to control usage. Free space is always returned to the underlying device. By doing this every device at every layer of your storage stack can consume as little or as much space as needed provided there is physical space available. The minimum requirement for this to work is that the top most block layer and bottom most layer are both dynamic but there are benefits to having all layers be dynamic. The dynamic top layer needs a method by which it can inform the underlying block device which portions of it are unused. This allows space to be returned to the free pool so it can be used by another device or another storage layer. Historically block devices could not communicate this to one another but this is now possible via a couple methods.

## Discard
The discard command was originally used by SSDs to allow you to request that blocks of storage be reset. The reset signal is much more efficient than writing zeros on memory chips as it eliminates the write requests that would normally be used to zero out storage space. It also allows the SSD to better manage itself. The discard command is issued by the filesystem, located at the top of the storage stack. This command trickles down through the other block layers (so long as discard is enabled) until it reaches a device that can process it or until it is blocked by a storage device layer without discard support.

## Zero-Based Free Space
Before discard was supported the only way to know that space is unused is that it is filled with zeros. When you delete a file from most file systems the previously used space is usually not zeroed out. It is left with its previous content still present and marked free in the allocation table. In order for the lower level block device to recognize it is free you must write zeros to the unused space. Monitoring IO traffic for blocks of zeros is computationally expensive so the block device may have a separate out of band reclamation process (sometimes manual) that is used to recognize zero blocks and take them out of service. By comparison to discard this method is primitive but effective if you manage the processes required to make it work.

# The Cost of Dynamic Storage
All dynamic storage layers use an allocation table that tracks which portions of a device are used. This table is the storage metadata. It generally breaks up the storage device into chunks that map virtual storage to actual storage. The cost of this on most dynamic systems is minimal by design and can be reduced further by increasing the chunk size. Here are the factors to consider:
* The metadata uses up some storage space.
* Latency is added to read operations because they must cross reference the allocation table with the virtual storage location to locate the data. This incurs processing time but the metadata is usually cached in memory because it is small.
* New block allocation latency is incurred on some write operations in addition to the metadata read latency when storage needs to be extended. This latency can be significant but is mitigated by systems that automatically expand storage ahead of time.

# Not All Storage is Dynamic
Thin provisioning is not available everywhere. However, this is not a problem so long as it is sandwiched by storage layers that can pass information through about free space. Below is a list of some layers that are not dynamic. As a general rule you will make block devices as large as possible on these layers because you are unable to manage them in any other way.

## Partition Table
This is the lowest level allocation table visible to software and the only one the BIOS can read. The only concept of free space is that which is not contained within a partition, and that is extremely inflexible since it is tied directly to hard disk geometry. As a general rule you should use the fewest partitions possible to avoid managing partition boundaries later. On an MSDOS partition table this is one partition. On GPT this is two partitions since you also need an EFI boot partition[^8].

## LUKS
LUKS encrypts the underlying block device, including the free space. A good encryption algorithm won't let an attacker be able to discover the difference between used space and free space. LUKS now allows you to pass through the discard command. Wait, what about not being able to discern free space from used? You are right. If you pass the discard command through LUKS to a block device that accepts it then it will be quite obvious which parts of your volume is used since the unused part will return all zeros. If you are trying to hide data in your encrypted volume this may not be what you want.

# Dynamic Storage Devices
All of the block device types below have the following attributes:
* Capable of multiplexing access by creating virtual block devices
* Provide a way to monitor free space
* Specify the location used for storing metadata
* Have a method to return free space to the pool

## Physical Storage
You may find it surprising to find physical storage on the list of dynamic storage devices. You can't magically make your disk larger and there isn't a way to return unused storage for a refund at your local Best Buy. Internally though modern storage devices do in fact have some spare storage. They are hot spares, waiting to be called into service when a memory chip goes or disk sector goes bad. The details are hidden away from you but you should still be [monitoring SMART](https://www.linuxjournal.com/article/6983) to ensure you do not run out of space. You need not worry about the overhead of this process since it is included in the device specifications. Only SSDs supporting discard have a way to return free space to the drive firmware's management routines.

## Storage Array / SAN
Storage arrays aggregate physical storage devices and present them as virtual storage to its clients, usually over fiber channel, iSCSI, or other network transport. We are specifically talking about storage arrays that support thin volumes here since they are the only ones that meet the criteria for dynamic storage. Overhead information and free space monitoring will have to come from your vendor. If you build the storage array yourself you should be able to estimate based on the information in this post or the other block devices you have used.

## Virtual Disks
Thin provisioned Virtual disks are provided by hypervisors as files for storing the hard disks of VMs. Multiplexing of access and tracking free space occurs on the hypervisor's filesystem while the metadata is stored with your VM. The allocation table metadata for your disk could be stored in the same file as the data or it could be stored in a second file dedicated to mapping data to used portions of the virtual disk. The method used to return free space to the hypervisor depends on the features your hypervisor supports. If it supports discard then it will likely be returned immediately, incurring the overhead of a filesystem operation on the hypervisor. If it supports zero-based free space you will need to address this in the file system and then recover the space using a hypervisor operation that will search for zero blocks remove them from your virtual disk file.

## Database Backing Devices
File systems and databases are very similar. Most database systems require you to create backing files in your filesystem but some [such as mysql](http://download.nust.na/pub6/mysql/doc/refman/5.1/en/innodb-raw-devices.html) let you store it directly on a block device. Database tables are at the same abstraction layer as files in a file system so while a file system provides concurrent access to multiple files, database systems provide concurrent access to multiple tables. Almost every database system has commands to monitor how much of the database files are free. In order to avoid new block allocation latency most database systems grow their files by adding large chunks of space to them and do not automatically shrink the files. To be able to return space to the filesystem these files must be configured to shrink automatically or, in the case of raw partitions, issue discards. This could be built in or you could schedule a job that compacts the database and reclaims some or all of the space.

## LVM
As most of us know LVM is the dynamic alternative to partition tables. Storage at the LVM level hasn't met the definition of dynamic storage as presented in this post until relatively recently when automatic space reclamation became available with thin volumes. `pvs` or `vgs` will show you how much free space is available. There are to storage areas for metadata. The first, stored in the first 192k of the physical volumes, map out allocation for the logical volumes. There isn't a built in method to automatically enlarge or shrink these volumes. LVM will pass discards to the underlying devic when you enable them but it won't do anything more in a standard volume. Enter thin volumes. A thin volume in LVM parlance is a logical volume containing the backing store for virtual volumes. After you create this backing store you can create virtual volumes within it that *do* respond to discards by eliminating the space the virtual volume consumes within the thin volume. You can check the free space in the thin volume with the `lvs` command. In addition you can configure LVM to autoextend[^10] the thin volume. Although this doesn't let you reclaim space automatically in the volume group it does minimize the size of the thin volume so that it can better coexist with other static volumes.

## File Systems
This is primarily where you experience the problems I've detailed here. No matter where you run out of space you will get an error from your file system. Your filesystem multiplexes access by enabling you to store many files and you can use the `df` command to view free space. The metadata is stored differently for every file system so consult your file systems' documentation[^9]. Most file systems now support mounting with the discard option which will free space immediately when you delete a file. This will also cause the delete operation to block until the discard is complete. You can avoid this performance penalty by mounting *without* discard and then occasionally running `fstrim -a`. If you are using zero based free space on your underlying device you can use a tool such as [zerofree](http://manpages.ubuntu.com/manpages/xenial/man8/zerofree.8.html) to empty out the unused blocks and then reclaim it using the process from the lower level device.

# So ... How Big?
Within dynamic layers you can use as much as needed without concern for disk space boundaries. For static layers there is inevitably some type of size estimation we must do as a matter of practicality. The reasonable limit to sizing static layers is no longer based on what you will use, but the limits of your physical system. E.g. if you have a hypervisor with 2TB of storage you could make all disks 2TB. Obviously no single disk with reach this limit. If you had a 2PB storage array you probably wouldn't use disks that are 2PB because few VMs would have a use case for this much storage. Use the maximum size you will allow any VM to use.

[^1]: Note that older SSDs were sometimes *slower* with the discard command enabled or even worse, unstable. Some SSD manufacturers will recommend you not bother with the discard command.

[^2]: If you are concerned about security you will also realize that the bad blocks are still there when they are decommissioned. You can't normally read them but that doesn't mean someone else can't find a way.

[^3]: There are exceptions to this. Shared disk configurations provide access to multiple VMs but don't multiplex access to the space. They only multiplex access to the virtual storage bus which is not the same. VMs are expected to figure out how to multiplex access to the storage.

[^4]: It is important to note that the hardware device has a partition table on it and that this partition table is the lowest level allocation table visible on the system using it. The partition table typically allocates space on the entire disk and is _not_ dynamic. Use the minimum number of partitions required (1 with an MSDOS layout, 2 on an GPT layout) and you will only need to worry about enlarging it when the disk is enlarged.

[^5]: Thin volumes is a recent addition to LVM. Traditional volumes on LVM are not dynamic but do still allow you to pass the discard command from the filesystem to the physical volume.

[^6]: Grub does not currently support booting from a thin volume. If your /boot volume is on LVM it must be a standard volume and not part of the thin pool.

[^7]: See `lvmthin(7)``

[^8]: Some flavors of Linux also require a /boot partition. This is unfortunate since grub has long supported booting from LVM. Make the /boot partition big enough so you don't run out of space for kernels and initramfs. On many systems this is 1GB.

[^9]: Note that on some filesystems the metadata scales linearly with the size of the volume, even when nothing is on it. This is because files system structures are written across the entire disk. This is relevant when considering how much space you waste on metadata. For example, if you create enormous file systems on thin LVM volume you may find that they are all using a space you consider significant even when there is nothing stored on the file system yet.
