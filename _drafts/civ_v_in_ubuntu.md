---
title: Run Civilization V in Ubuntu On a Second Monitor
date: 2019-09-28 00:00:00 Z
categories:
- Ubuntu
tags:
- games
---

I recently decided to start playing Civ V on Steam. The thing is the games last for hours and I really don't want to be stuck in the game unable to do anything else. This is easier said than done.

# Contents
* TOC
{:toc}

# Prerequisites
* You have purchased and installed the game from Steam
* You have a second monitor plugged in and configured for use.

# Fullscreen or Windowed?
There are two main factors to consider when asking this question.
0. How much more slowly will the game run in a window? When the game is fullscreen the video bypasses X entirely so it can draw straight to the screen. The performance hit varies depending on your configuration but it is usually significant.
0. Does my desktop resolution match what the game expects? In my case my laptop has a 4k display. At this resolution Civ V is unplayble, not to mention it will be extremely slow with all those pixels to draw.
In most cases the clear choice is to run it fullscreen. That means you are dedicating a monitor to the game.

# But Which Monitor?
When launched fullscreen the game always opens on the primary monitor. The problem is that the desktop is also on your primary monitor. Most new windows will also open on the primary monitor. This means your primary monitor is a poor choice to run the game on. This is a bit inconvenient since the game will always launch on the primary. This is the fastest way to work around it:
0. Launch the game. It opens fullscreen.
0. Change the resolution of the game to what you will be using on the second monitor and apply it. Your primary monitor has to be able to display this resolution. (If for some reason it can not then you will probably need to always set the game back to windowed mode before you exit, which is a hassle.) You only have to do this once since the game will remember next time.
0. Enabled windowed mode and apply it. Your game will snap to a window on your desktop.
0. Move the game to your second monitor. The entire window might not fit on the second monitor but that is ok. If X remembered your window position from last time it will appear on the second monitor on its own soon as you go to windowed mode.
0. Set it back to fullscreen and click apply. The game should now be fullscreen on your second monitor.
Unfortunately you are going to have to repeat this procedure whenever you launch the game. A bit annoying but you only have to do this at launch.

# Switching to Other Windows
If you have followed along so far you now have the game running fullscreen on the second monitor. You might have noticed that you can move your mouse back to your main display but soon as the game window loses focus it minimizes. This is not something we want to happen not only because we can't see our game and the extra step of restoring it, but also because minimizing full screen windows can lead to video corruption on some systems. It turns out there is a variable we can pass to Steam games to fix this. You can set it globally but the easy way is to just apply it to this one game. To do that:
0. Open the Steam launcher and find the game in the Library
0. Right click on the entry for Civ V and click "Properties"
0. Click on the "Set Launch Options" button
0. As the command paste this in: `SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 %command%`
You can find more info in [Steam for Linux Issue #4769](https://github.com/ValveSoftware/steam-for-linux/issues/4769) but I give credit to [this](https://www.reddit.com/r/linux_gaming/comments/3gci3a/civ_v_and_others_automatically_minimize_when/) Reddit post for saving me.
![Civ V Launcher Variable](/images/civ_v_launcher_var.png)

# What About the Music?
The game now runs on a second monitor and you can multitask but every time you switch to a different task the music will mute. Unfortunately I don't have a solution to this though I spent a good amount of time looking for one. If you figure out how to fix it please let me know!
