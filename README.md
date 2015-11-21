#Work in progress. Use at your own risk

An ApplesScript that speeds up tracks and applies compression to improve listenability of files with low audio levels.

Dependencies:

* sox
* lame
* id3lib
* eyeD3

Add this post commit hook to compile script and place output in your iTunes Scripts folder

``` Shell
osacompile -o make\ fast.app make\ fast.applescript 

if [ -e ~/Library/iTunes/Scripts/make\ fast.app ] 
	then rm -rf ~/Library/iTunes/Scripts/make\ fast.app
fi

mv -f make\ fast.app ~/Library/iTunes/Scripts/make\ fast.app
```