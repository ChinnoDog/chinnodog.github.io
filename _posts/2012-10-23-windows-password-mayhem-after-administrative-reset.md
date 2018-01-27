---
title: Windows Password Mayhem after Administrative Reset
date: 2012-10-23 08:51:01 -04:00
permalink: "/windows-password-mayhem-after-administrative-reset/"
categories:
- Windows
tags:
- active directory
- fixes
- security
---

I recently forgot my password at work. On a single domain this is pretty painless to recover from but at work I have accounts and passwords on a multitude of domains and always connect back to some shared drives elsewhere on the network in order to get the files I need. The servers I connect to are running Server 2008 R2. The drives are on a different domain than the servers I connect to them from; presumably the file server is also running Server 2008 R2. As a result of the cross-domain connection Windows caches the credentials for these drives locally. This cache normally gets expired when I change my password and I have to type in my password again and everything is well again. However, the administrative password change process is different than the one used when you change your own password. I do not know exactly what is different but Windows is no longer able to expire the remote passwords in the cache. The result is that I have my old password cached all over the place. The instant I try to use a server with my cached password I get locked out of my company's domain. That is, the server I am connected to via RDP attempts to authenticate to the server with the remote drive using expired credentials and then when it fails it repeats the process in a matter of microseconds until my account is locked out. Worse than that, it seems like the cache never expires. I finally found the solution. On every server I connect to, _before_ mapping any drives, I have to run this:

    cmd /c net use * /delete /y && C:\Windows\System32\rundll32.exe keymgr.dll, KRShowKeyMgr

This process could use some refinement. The first statement runs without a problem but the the second one opens the Key Manager and requires me to manually delete all of my cached passwords. Both of these must be run! The credentials are apparently stored in two different places. If there were more servers I would have taken the time to figure out how to programmatically flush the cache managed by keymgr.dll but I have it mostly solved now and am crossing my fingers that never happens again. If anyone can tell me how to flush the cache managed by keymgr.dll without a graphical dialog I would be in your debt. I would then be able to use [psexec](http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx) to remotely flush my credentials without logging in.
