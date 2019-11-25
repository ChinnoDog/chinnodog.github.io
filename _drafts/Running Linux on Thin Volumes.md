---
title: The End of Disk Space Management in Linux
date: 2018-10-31 00:00:00 Z
categories:
- Ubuntu
tags:
- security
- grub
---

What admin isn't familiar with the plight of running out of disk space? You would think this issue that affects everyone and saps our time would have been eliminated by now but it definitely has not. We can't eliminate the issue entirely but we can get pretty close. The only thing we can't do is make physical storage space magically increase. (If you find a way to do this please do let me know. :D )

# Contents
* TOC
{:toc}

# About Allocation Tables
Before discussing methods to eliminate disk space management we need to talk about the technology used to make storage dynamic. That is the allocation table. There are many forms of the allocation table including file system allocation tables, LVM thin volume metadata, VMware thin volume files containing metadata, physical storage arrays that supports thin volumes, and bad sector maps in SSD devices. Every instance of an allocation table ensures that you know which parts of the block storage you are using and which parts you are not so that each can receive the appropriate treatment. In order to make your storage fully dynamic we have to consider several things about each allocation table.
* How much overhead does storing the allocation table create? Tracking used and unused clusters is not free. The allocation table is metadata that must be stored in addition to the actual data and will use additional storage space and IO cycles.
* What happens when I run out of space? Unhandled out-of-space issues are a problem on every system. There must be a clear and obvious set of steps that occur or Bad Things will happen.
* How much free space is there? This is the corollary question to "How much space have I used" and arguably is the more important question when managing your storage. The data you store typically uses more space than the size of the data. Compound that with multiple layers of allocation tables and understanding how much free space you have can become quite tricky.
* Where is the free space used for? This is device specific. Sometimes the free space can be ignored. At other times it is zeros, does not exist, or is undefined.
Let's start with the lowest levels of storage and work our way up.

# Physical Storage
This is the hard limit we can't do anything about except add more storage. There are some things to know about it though.

## SSD
SSDs are actually made of memory blocks that wear out. Internally the SSD manages an allocation table for all available blocks that includes the ones you have access to as well as some spares. It also allows you to pass the "discard" command, which is a special instruction that will reset the memory blocks to zero without needing to actually write zeros to them. The only thing we need to know is weather our particular SSD benefits from sending the discard command. Older SSDs were sometimes *slower* with the discard command enabled or even worse, unstable. If you want the benefits of discard then you need to enable it on whatever filesystem is directly on top of your SSD weather that is a Linux filesystem or LVM.
* How much overhead? Unknown. It is hidden by the hardware implmentation.
* What happens when I run out of space? Your SSD starts its slow crawl towards death by accumulated bad sectors. Replace your drive before this happens if possible.
* How much free space is there? We don't know because the hardware manufacture typically does not advertise the number of spare blocks.
* What is the free space used for? They are all hot spares. Soon as a used block goes out of service the spare is used to replace it.

## Storage Arrays
Some storage arrays promise support for thin volumes. This means that they will expose block devices to clients that internally are stored as thin volumes. The results of this are implementation dependent. If you are using one of these just be sure you have a way to track how much free space you have and know what happens when you run out of space so you aren't subject to any nasty surprises.
* How much overhead? Implementation dependent.
* What happens when I run out of space? Definitely find out in writing. Be scared.
* How much free space is there? Implementation dependent.
* What is the free space used for? Nothing. It is sitting there unused with unknown contents.

# Virtual Storage
This is storage that is provided by a hypervisor, typically in the form of a virtual disk file. In order to get the most out of your virtual storage you will need to use thin volumes.
