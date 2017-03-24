
An ApplesScript that speeds up tracks and applies compression to improve listenability of files with low audio levels.

If the track does not have album and artist metatdata either or both will be copied from the name of the track's parent folder 

Dependencies:

* sox
* lame

Add this post commit hook to compile script and place output in your iTunes Scripts folder

``` Shell
osacompile -o make\ fast.app make\ fast.applescript 

# you can't just overwrite it because a something.app is a directory not a file
if [ -e ~/Library/iTunes/Scripts/make\ fast.app ] 
	then rm -rf ~/Library/iTunes/Scripts/make\ fast.app
fi

mv -f make\ fast.app ~/Library/iTunes/Scripts/make\ fast.app
```
