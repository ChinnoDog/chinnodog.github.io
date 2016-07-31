---
title: Changing Dell Touchpad Sensitivity in Windows 8
date: 2013-09-12T14:24:59+00:00
permalink: /changing-dell-touchpad-sensitivity-in-windows-8/
categories:
  - Windows
tags:
  - Dell
  - Productivity
  - Windows 8
---
It is most annoying when one is trying to type and is constantly hitting the touchpad by accident. Palm check controls will help reduce this when typing but unless sensitivity is turned down it will constantly happen when not typing as well. So, I opened the touchpad applet from the tray on my new Dell E6530 to fix this and I found...

![dell missing touchpad controls](/images/dell_missing_touchpad_controls.jpg)

Wait, something is missing! I can enable the palm check but there is no sensitivity adjustment. Naturally I checked the mouse properties control panel applet as well.

![useless dell tp tab](/images/useless_dell_tp_tab.jpg)

This was also useless. A search for the right ALPS touchpad driver ensued. Many Google searches and driver versions later I still did not have a solution. Then, finally, I discovered the secret. The controls aren't in the applet, they are buried somewhere else! Just run `C:\Program Files\DellTPad\DellTPad.exe` and this hidden executable will display all the settings that are missing.

![missing dell settings](/images/missing_dell_settings.jpg)

I could not find a link or shortcut to this executable anywhere. Apparently you just have to know it is there. They couldn't have made it any easier, right?
