# vim-gitinfo
A vim plugin created by ChatGPT-4 (and me) to display the last commit info of current line.

![image](./gitinfo.gif)

This plugin code is mostly written by ChatGPT-4. What I did is telling ChatGPT-4 what I want 
and fix thoes bugs that ChatGPT-4 cannot handle itself (after I instruct him for infinite times).

## prerequisite
+ This plugin requires lua5.3
+ This plugin depends on another plugin [`infoboard`](https://github.com/RickiZhang/vim-infoboard)

## installation
Just create a directory `gitinfo` under `~/.vim/plugin/`, and place the gitinfo.vim into it

## usage
Type `:ToggleGitInfo` in the command line to enable or disable this plugin, commit info will be displayed
in the 'gitinfo' tab of the infoboard.

## note
+ It won't be enabled unless you type and enter `:ToggleGitInfo` in your vim command line (this can 
also used to disable it).
+ It won't show anything if the working directory of current vim process does not contain a .git directory.
+ I know there are many plugins that contains the same feature and work way better than mine. So this is yet another example to show 
what ChatGPT-4 can do.

