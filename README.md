# vim-gitinfo
A vim plugin created by ChatGPT-4 (and me) to display the last commit info of current line.

![image](./gitinfo.gif)

This plugin code is mostly written by ChatGPT-4. What I did is telling ChatGPT-4 what I want 
and fix thoes bugs that ChatGPT-4 cannot handle itself (after I instruct him for infinite times).

## installation
Just create a directory `gitinfo` under `~/.vim/plugin/`, and place the gitinfo.vim into it

## usage
Just stop moving the cursor for about 1.5 sec and a commit info line will be pop-up above the cursor line.

## note
+ It won't be enabled unless you type and enter `:ToggleGitInfo` in your vim command line (this can 
also used to disable it).
+ It won't show anything if the working directory of current vim process does not contain a .git directory.
+ Better disable it before enter from normal to other modes


