---
title: Elevated Explorer Window in Windows 8 in One Command
date: 2013-09-13T17:11:11+00:00
permalink: /elevated-explorer-window-in-windows-8-in-one-command/
categories:
  - Windows
tags:
  - security
  - sysadmin
  - Windows 8
---
The problem: Windows 8 forces you to run with UAC enabled if you want Metro apps to work, and that means that all of your explorer windows run without elevated privileges. I know, UAC woes are old news! There are lots of guides out there about various ways to "trick" Windows into opening Explorer with with an admin token. They all have problems though, such as:

  * The procedure no longer works on Windows 8.
  * Additional tools are required that aren't present in a default Windows 8 installation.
  * Preparation is required ahead of time
  * It changes the configuration of my user profile or of the computer

I don't find any of these exceptions acceptable for normal administration of a Windows PC and frankly I'm appalled that Microsoft did not supply an easy way to do this (among other things). So now I present to you the solution to elevating your Explorer permission in two steps:

  0. Press the windows key to open the metro interface and type the following command:

          cmd /c taskkill /fi "username eq %username%" /im explorer.exe /f && explorer

  0. Press ctrl+shift+enter to run the command with elevated permissions.

Explorer will immediately terminate and respawn. All subsequent windows will be elevated. If you want to relaunch explorer without the admin token you will need to kill it and launch it from task manager or other location that can produce a user level token. Some notes on this solution:

  * This is designed to work on shared systems so that you don't kill everyone else's explorer session in the process.
  * This doesn't seem to work when explorer is run in separate processes. The default is to run in a single process and I like conserving resources so I didn't bother investigating this any further.
  * I can't think of a reason you couldn't configure this to run at start up though it doesn't seem wise. See below.

Now before you get all excited thinking that this solves everything (like I did) realize that once you have done this you will not be able to see tray applications running with a user token and applications launched will complain they were launched with admin privileges. So in the end, this is just a crutch. If anyone has a better way to do this that doesn't require reconfiguring the computer first please do tell.
