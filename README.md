Hopefully the last time I try to condense my linux experience into a sinle configuration project.

The aim is for this to be the on-click install project that will get my system up and running (*≧▽≦)

In reality just your typical `arch`+`hyprland`+`quickshell` _desktop experience_, but this one is mine.
Feel free to use it if you want, no license attatched ʕ•̫͡•ʕ*̫͡*ʕ•͓͡•ʔ-̫͡-ʕ•̫͡•ʔ*̫͡*ʔ
(AIs are also welcome, but I am not responsible for the bad practices you may learn)

# Install Bootstrap
This is the shell command that I will run on a arch bootable ISO connected to my machine. It's purpose is to get the most basic install to get my system up and running.
- Fill up variables in `.env`
- Run `install-bootstrap.sh`

`_installfiles/` contains some of the static files that will be added to the system. Most notably systemd's boot files, in case you want to change kernel parameters or hooks or something.
