---
title: Stop Managing Your Disk Space
date: 2019-11-26 00:00:00 Z
categories:
- Ubuntu
tags:
- security
- grub
---

As a Linux user I would like to never see another "out of space" message ever again. Secondary storage space limitations is a problem almost as old as computers themselves. Why are so many of us constantly running into this barrier a half century later? The only insurmountable barrier to disk space issues is the size of the physical storage device. We can't (yet?) waive a magic want and make our physical disks grow in size. For every virtual device layer built on the physical storage there are ways to make the limits dynamic if we choose to use them.

# Contents
* TOC
{:toc}

# What is Dynamic Storage?
Linux secondary storage typically consists of multiple layers of block devices, each one layered on the next. Each block device layer has a mixture of used space that currently contains valid data and free space that is unused. "Dynamic" in the sense I am using here means that the used space can grow and shrink freely and the unused space can be returned to the system to be consumed as needed.

# The Problem
Block device layers historically could not communicate their usage with one another. This means that what happens in one block device layer isn't visible to the layer beneath it. E.g. If you have an XFS volume on an LVM logical volume then the LVM subsystem only knows which space belongs to your XFS volume and not how to interpret the data in your XFS filesystem. This means that free space and used space on the top layer is indiscernible to the layer beneath it. There now exists methods to communicate free block information information between layers. By using these methods we can ensure that unused space is recognized at every level so it is available by any layer that needs it.

## Allocation Tables
Every shared block device has an allocation table, a storage area dedicated to tracking which parts of your storage are consumed. In order to make your storage fully dynamic we have to manage these tables so they can be managed by software and not the users. We have to know how much of the block device is used, how much is free, and sometimes how much space the allocation table itself takes up.

## Multiplexing
In addition to tracking how much space is used most block device layers also multiplex access to the block device such that multiple entities can have concurrent access. This is not directly relevant to the free space problem. I mention in here since this capability is often built into the allocation table and I want to call out this feature so that we can avoid confusing it with allocation function.

# Block Devices
All storage in Linux is on a block device. In order to form a complete picture for each block device layer I'm going to list a series of attributes for each block device layer in sections below.

| Attribute | Comments |
|-|-|
| Allocation Table | The structure that stores information about which sectors are used. |
| Overhead | How much overhead does storing the allocation table create? Tracking used and unused clusters is not free. The allocation table is metadata that must be stored in addition to the actual data and will use additional resources. |
| Exhaustion | What happens when I run out of usable storage? Unhandled out-of-space issues are a problem on every system. There must be a clear and obvious set of steps that occur or Bad Things will happen. |
| Free Space | How do you know how much free space is available? The data you store typically uses more space on disk than the size of the data. |
| Negative Space | What is the free space used for? Sometimes the free space can be ignored. At other times it is zeros, does not exist, or is undefined. |
| Interface | How the block layer above can notify this one that space is unused.
| Multiplexing | How access to the storage device is shared. |

Let's start with the lowest levels of storage and work our way up.

# Physical Storage
This is the hard limit we can't do anything about except add more storage.

## SSDs and Hard Drives
Both SSDs and hard drives have sectors that that wear out. Modern drives internally manage an allocation table for all available blocks that includes the ones you have access to as well as some spares. Bad sectors are replaced by good ones by the device's firmware so you don't even notice they have gone bad.

| Factor | Comments |
|-|-|
| Allocation Table | Proprietary, probably stored in firmware somewhere |
| Overhead | Hidden by the hardware implementation. Hidden bad sectors can produce unusual seek times on spinning disks but beyond that only the manufacturer knows. |
| Exhaustion | Your device runs out of hot spares to swap in and starts accumulating bad sectors which lead to its eventual demise. Check how close you are by [monitoring SMART](https://www.linuxjournal.com/article/6983) on your drive. Unfortunately this is not perfect as you are relying on the manufacturer of your drive to alert you before your drive croaks on you, but is the best we have. |
| Free Space | The hardware manufacture typically does not advertise the number of spare blocks. Rely on the SMART statistics instead to let you know when the drive is nearing its end. |
| Negative Space | We can generally assume they are all hot spares, sitting there until they are called into service to replace a bad block[^2]. |
| Interface | SSDs allow you to pass the "discard" command, which is a special instruction that will wipe a memory block by sending a reset signal to the chips instead of writing zeros to them[^1]. Hard disks don't have a discard command for individual blocks; the closest they come is the [secure erase](https://ata.wiki.kernel.org/index.php/ATA_Secure_Erase) command that erases the entire drive.
| Multiplexing | None. The storage device only knows itself and what is used. It does not know anything about its own contents.

## Storage Arrays and SAN devices
These devices segment physical storage devices into multiple block devices that can be presented to physical or virtual systems. Some storage arrays promise support for thin volumes. This means that they will expose block devices to clients that internally are stored as thin volumes. Though the block devices presented to clients are actually virtual devices I present this under physical storage because it is a black box for most intents and purposes, much like physical storage devices.

| Attribute | Comments |
| | |
| Allocation Table | Implementation dependent, but likely similar to virtual storage. |
| Overhead | Read your specs. |
| Exhaustion | Bad Things happen. It is likely attached clients will crash. Be scared, and don't let this happen.  |
| Free Space | Implementation dependent free space monitor. Ideally loud sirens and lights go off and the storage fairies are summoned. |
| Negative Space | Unused space usually sits there, burning a hole in your storage budget. |
| Interface | Usually the volume is presented as all zeros and nonzero sectors will be used to track space. What about sectors that you wrote to but then wrote zeros to after? Ask your vendor.
| Multiplexing | The primary function of your array is to multiplex access by converting a pool of physical devices into a pool of virtual block devices.

# Virtual Storage
This is storage that is provided by a hypervisor, typically in the form of a virtual disk file. The disk files are like any other, sitting on top of a filesystem on the host. In order to dynamically allocate storage you must use thin volumes.

| Attribute | Comments |
| | |
| Allocation Table | The virtual disk file contains the allocation table. Some systems split the allocation table into a separate file. Either way the used blocks of the VM are mapped in this file.
| Overhead | Using thin volumes incurs disk seek overhead from having to first consult the allocation table. The size of the extents are inversely proportional the the performance penalty. |
| Exhaustion | You can no longer consume more disk space without complaining to your hypervisor admin. |
| Free Space | The hypervisor initially presents a disk that contains all zeros but in actuality doesn't consume any space on the disk. As you write data to the disk the hypervisor marks these sectors as used. |
| Negative Space | Ideally the unused space doesn't actually exist and does not consume any space in the virtual disk file. |
| Interface | The hypervisor knows your disk space is unused when it contains zeros. This is a problem since filesystems typically do not zero out unused space. Even if you do zero it out not every hypervisor is going to monitor the disk for zeros. How exactly you reclaim space is hypervisor dependent. Some hypervisors accept the discard command. Others might expect you to run a command to reclaim it. |
| Multiplexing | The virtual disk has one user, and that is the VM that it is connected to[^3]. |

# Partition Tables
This is the first allocation table written by the installed operating system. It is ancient, and it is weak, but it is the only one that the BIOS knows about. Unfortunately, it is not dynamic.

| Attribute | Comments |
| | |
| Allocation Table | The area at the beginning of the disk below the 64kb boundary. There are many partition table types but as far as limitations they are pretty similar. |
| Overhead | Overhead is virtually nonexistant because it is tiny and barely does anything beyond the initial disk configuration. |
| Exhaustion | If the disk is virtual or the disk is copied byte-for-byte to a larger disk the partition table can be updated to once again extend to the end of the disk. |
| Free Space | If there is space on the disk not listed in the partition table then it is free. |
| Negative Space | The unused space is assumed to exist but has unknown contents. |
| Interface | There isn't a way for partition tables to tell the hard disk which portions are empty. Virtual and physical disks use the data written to the sectors to determine usage so this generally isn't important. |
| Multiplexing | The partition table allows creation of multiple partitions, but they must consist of contiguous space. This is not a very dynamic layout! To avoid this limitation it is best to use as few partitions as possible. An MSDOS partition table only needs one partition for the whole disk. A GPT partition table requires a small partition for EFI boot in addition to the one for the rest of the disk. |

# LVM
The logical volume manager is here to save us from the shortcomings of the partition table. It also has many other features such as built in software RAID and the ability to span multiple physical disks. The feature we care about most is relatively new, and that is thin volumes.

| Attribute | Comments |
| | |
| Allocation Table | The LVM metadata area is created when you format a partition as LVM. |
| Overhead | The metadata typically occupies 192k. The physical disks are divided into extents which are uniformly sized chunks of disk space. The amount of metadata generated is inversely proportional to the extent size used on the disks. Because extents are assigned to logical volumes as requested a given volume could be located on arbitrary sections of disk. The impact of this can usually be ignored but could be important when planning the location of swap or database volumes. |
| Exhaustion | When you run out of space LVM will inform you at the time you extend the disk. Out of extents! |
| Free Space | You can run the lvs command |
| Negative Space | Unused space is not accessible and is undefined. |
| Interface | Enabling discard passthrough allows LVM to inform the underlying disks when space is freed. This only helps if you are using an SSD or virtual disk supporting discard. |
| Multiplexing | LVM allows creation of an arbitrary number of volumes to be mounted as independent block devices |

# Filesystems
Only modern filesystems are considered here but this may apply to some older ones too.

| Attribute | Comments |
| | |
| Allocation Table | Each filesystem has its own allocation table format built for tracking its files. |
| Overhead | There are books about this and I won't begin to attempt covering it here. Read your man pages! |
| Exhaustion | You receive the infamous out of space message! Then processes start hanging and crashing and your log fills up with nastygrams about disk space unavailable. |
| Free Space | The 'df' command can tell you how much space is available. |
| Negative Space | The unused space is littered with the remains of deleted files and other garbage. |
| Interface | Almost every filesystem supports the discard command to inform the underlying block device that the space is no longer consumed. |
| Multiplexing | All filesystems divide the space into files. btrfs and zfs additionally allow multiple mount points on the same volume. |

[^1]: Note that older SSDs were sometimes *slower* with the discard command enabled or even worse, unstable. Some SSD manufacturers will recommend you not bother with the discard command.

[^2]: If you are concerned about security you will also realize that the bad blocks are still there when they are decommissioned. You can't normally read them but that doesn't mean someone else can't find a way.

[^3]: There are exceptions to this. Shared disk configurations provide access to multiple VMs but don't multiplex access to the space. They only multiplex access to the virtual storage bus which is not the same. VMs are expected to figure out how to multiplex access to the storage.
