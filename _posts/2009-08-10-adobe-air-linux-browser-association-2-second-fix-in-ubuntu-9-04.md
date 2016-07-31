---
title: Adobe Air (Linux) Browser Association 2-Second Fix in Ubuntu 9.04
date: 2009-08-10T10:46:57+00:00
permalink: /adobe-air-linux-browser-association-2-second-fix-in-ubuntu-9-04/
categories:
  - Internet
---
The early versions of Adobe Air wouldn’t open links in twirl in Chrome when I ran it on Windows.  The current version won’t open links in Chromium when I run it in Ubuntu.  I found [this](http://web.archive.org/web/20110203085002/http://blog.torh.net/2009/07/30/adobe-air-open-urls-in-default-browser/) article that indicates the problem and fix. Here is the two line version of the fix. Adjust it if you aren’t running Ubuntu 9.04 (Intrepid) or wish to use a different browser.

```bash
sudo perl -i.bak -p -e 's/firefox/browser/g' /opt/Adobe\ AIR/Versions/1.0/libCore.so
sudo ln -s /usr/bin/chromium-browser /usr/bin/browser
```

Note: This modifies part of Adobe Air, and you will probably have to rerun the first line if you install an Air upgrade. If this blows up your Air install just delete libCore.so and rename libCore.so.bak to libCore.so.
