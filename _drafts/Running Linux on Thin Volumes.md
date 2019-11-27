---
title: Stop Managing Your Disk Space
date: 2019-11-26 00:00:00 Z
categories:
- Ubuntu
tags:
- security
- grub
---

Secondary storage space limitations is a problem almost as old as computers themselves. Why are so many of us constantly running into this barrier a half century later? We can't magically extend physical storage (yet?) but we can at least avoid running into size limitations within our software.

# Contents
* TOC
{:toc}

# The Problem
Linux secondary storage typically consists of multiple layers of block devices, each one layered on the next. Each block device layer has a mixture of used space that currently contains valid data and free space that is unused. These block device layers typically can't communicate with one another though. The result is that free space on one layer is indiscernible from used space to the layer beneath it. Without knowledge of which blocks are unused in the higher level block device there is no way for the lower level device to make better use of the free space.

## Allocation Tables
Every shared block device has an allocation table, a storage area dedicated to tracking which parts of your storage are consumed. In order to make your storage fully dynamic we have to manage these tables so they can be managed by software and not the users. We have to know how much of the block device is used, how much is free, and sometimes how much space the allocation table itself takes up.

## Multiplexing
In addition to tracking how much space is used most block device layers also multiplex access to the block device such that multiple entities can have concurrent access. Though not directly relevant to the free space problem it is important to understand how this is being done on some layers so that we can manage the underlying storage.

# Block Devices
All storage in Linux is on a block device. In order to form a complete picture for each block device layer I'm going to list a series of attributes for each block device layer.

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
| Overhead | Unknown. It is hidden by the hardware implmentation. |
| Exhaustion | Your device runs out of hot spares to swap in and starts accumulating bad sectors which lead to its eventual demise. Check how close you are by [monitoring SMART](https://www.linuxjournal.com/article/6983) on your drive. Unfortunately this is not perfect as you are relying on the manufacturer of your drive to alert you before your drive croaks on you, but is the best we have. |
| Free Space | The hardware manufacture typically does not advertise the number of spare blocks. Rely on the SMART statistics instead to let you know when the drive is nearing its end. |
| Negative Space | We can generally assume they are all hot spares, sitting there until they are called into service to replace a bad block[^2]. |
| Interface | SSDs allow you to pass the "discard" command, which is a special instruction that will wipe a memory block by sending a reset signal to the chips instead of writing zeros to them[^1]. Hard disks don't have a discard command for individual blocks; the closest they come is the [secure erase](https://ata.wiki.kernel.org/index.php/ATA_Secure_Erase) command that erases the entire drive.
| Multiplexing | None. The storage device only knows itself and what is used. It does not know anything about its own contents.

## Storage Arrays and SAN devices
These devices segment physical storage devices into multiple block devices that can be presented to physical or virtual systems. Some storage arrays promise support for thin volumes. This means that they will expose block devices to clients that internally are stored as thin volumes. The results of this are implementation dependent. If you are using one of these just be sure you have a way to track how much free space you have and know what happens when you run out of space so you aren't subject to any nasty surprises.
* How much overhead? Implementation dependent.
* What happens when I run out of space? Definitely find out in writing. Be scared.
* How much free space is there? Implementation dependent.
* What is the free space used for? Nothing. It is sitting there unused with unknown contents.

# Virtual Storage
This is storage that is provided by a hypervisor, typically in the form of a virtual disk file. In order to get the most out of your virtual storage you will need to use thin volumes.

[^1]: Note that older SSDs were sometimes *slower* with the discard command enabled or even worse, unstable. Some SSD manufacturers will recommend you not bother with the discard command.

[^2]: If you are concerned about security you will also realize that the bad blocks are still there when they are decommissioned. You can't normally read them but that doesn't mean someone else can't find a way.
