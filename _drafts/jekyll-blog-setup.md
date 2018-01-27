---
title: How to set up a blog with Jekyll and Minimal Mistakes
date: 2018-01-27 17:28:00.049000000 -05:00
---

This is a quick and dirty guide on how to set up a blog with [Jekyll](https://jekyllrb.com/) and the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/)[^1] theme for free using [Github Pages](https://pages.github.com/). Both Jekyll and Minimal Mistakes are well documented. Use this guide if you are too lazy (or efficient!) to absorb all that before you get started.  These instructions work on any operating system[^2].

[^1]: Minimal Mistakes is a great looking theme by [Michael Rose](https://mademistakes.com/) that I use for my own site. He has done most of the heavy listing including documenting all of the configuration options provided. I'm just filling in the blanks.

[^2]: You can theoretically set up and manage the entire web site from a tablet. Would tablet instructions be useful? Let me know in the comments if you think so.

# Prerequisites
* You want to build a blog using a static web site generator. If you aren't sure why or if you want a static site then read [An Introduction to Static Site Generators](https://davidwalsh.name/introduction-static-site-generators).
* You have a [GitHub](https://github.com/) account. Sign up now if you don't.
* Git is configured on your computer. Follow [these directions](https://help.github.com/articles/set-up-git/) if you have not already. Make sure SSH access is working for you.
* You have a text editor and know how to use it. Notepad or gedit will do but I highly recommend [Atom](https://atom.io/) if you want all the bling.

# Important Facts
* Your interface to Jekyll is going to be a directory full of text files. If that is too much for you then run away now. It only gets more difficult from here on in.
* Jekyll's files are controlled by git. You don't have to know how to use git to use these directions but you will wish that you did when you see the output and your eyes glaze over.
* The Jekyll site must be compiled by the Jekyll program but I'm not going to have you install it. Github is going to build it for you!
* A traditional "theme" is a web site skeleton that has been modified and enhanced with additional features. The concept of [themes in the Jekyll documentation](https://jekyllrb.com/docs/themes/) is new. As of this writing there aren't any useful themes of this type available.

# Instructions

0. Follow the first part of [Minimal Mistakes Quick Start](https://mmistakes.github.io/minimal-mistakes/docs/quick-start-guide/) to clone the repository. Don't follow the rest of the Quick Start quite yet. You can do that later.
0. Verify that `http://username.github.io` goes to your freshly created web site.
0. Open a [git] command prompt. Relax, you will only need this for initial setup and to commit changes to your website.
0. Type `git clone git@github.com:username/username.github.io.git` where "username" is your github user name. This will download your web site to your computer.
0. Enter the web site directory from the command prompt with `cd username.github.io`. The remainder of the directions assume your command prompt is in your web site directory sinc ethat is where you must run all git commands.
0. Open `_config.yml` in a text editor. If you are using Atom you can just type `atom .` at the command prompt for a view of all files in the directory.
0. Under `# Site Settings` set the title and description for the blog. Set the name to be your name.
0. Under `# Site Author` fill in your information. Add your username for any of the listed accounts you want the world to know about.
0. Save `_config.yml`.
0. Create a `_posts` directory in your web site directory.
0. Within the `_posts` directory create a file name in the format of `YYYY-MM-DD-first-post.md`. For example, for August 3, 2016 the file would be called `2016-08-03-first-post.md`.
0. Open the file in your text editor and place the following lines at the top:
```markdown
---
title: First Post
---
Place some text here. You will be able to change this later.
```
0. Save your first post. Your web site is ready but you still need to upload it to Github.
0. Type `git add .`[^3] at the command prompt. This will stage your changes.
0. Type `git commit -m "First Post"` to commit your changes to your local repository.
0. Upload the site by typing `git push`. Your site will be sent to Github. Shortly thereafter it will appear on `http://username.github.io`.

[^3]: This is a bad practice and it is lazy. If you know how to use git you can do this the right way. Otherwise, keep doing it this way and it will work out fine.

# Conclusion
Whew, you did it! Pat yourself on the back. You have created a blog with a first post but there is still a lot of work to do before you can brag to all your friends about your awesome blog. You have no doubt noticed how you create a basic blog post. You can continue making more of them in the same way. The same three git commands run afterwards will update the site. Read the following when you have time.
* [Minimal Mistakes Quick Start](https://mmistakes.github.io/minimal-mistakes/docs/quick-start-guide/) - Definitely read the rest of the guide to finish setting up your `_config.yml`. There are many other features and settings that you will want to use.
* [Jekyll Documentation](https://jekyllrb.com/docs/home/) - Explains the site structure and how things work. Also tells you how to install Jekyll on your workstation if you so desire.
