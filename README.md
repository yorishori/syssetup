Hopefully the last time I try to condense my linux experience into a sinle configuration project.

The aim is for this to be the on-click install project that will get my system up and running (*≧▽≦)

In reality just your typical `arch`+ ~`hyprland`~ `sway`+`quickshell` _desktop experience_, but this one is mine.
Feel free to use it if you want, no license attatched ʕ•̫͡•ʕ*̫͡*ʕ•͓͡•ʔ-̫͡-ʕ•̫͡•ʔ*̫͡*ʔ
(AIs are also welcome, but I am not responsible for the bad practices you may learn)

# Installing
This is the shell command that I will run on a arch bootable ISO connected to my machine. It's purpose is to get the most basic install to get my system up and running.
1. Install git in the bootable media.
2. Clone this repo in a none root directory.
3. Fill up variables in `.env`
4. Run `./install-boot.sh` (this will wipe the selected drive)
5. Boot into new system.
6. Connect to the internet.
7. Run `./install-system.sh`

`_installfiles/` contains some of the static files that will be added to the system. Most notably systemd's boot files, in case you want to change kernel parameters or hooks or something.

`config/` contains all the files that will be added to the system after everything is installed.



# Once Installed
As is inevitable, changes might be made and you wont want to reinstall the OS.
```bash
# From the root of the project and with your user
# Dry run
rsync -aivn --exclude='home/' config/ ~/.config/
rsync -aivn ./config/home/ ~/

# Real run
rsync -aiv --exclude='home/' config/ ~/.config/
rsync -aiv ./config/home/ ~/
```

You're welcome future me (or whoever's brave enough to do _this_ to their system).
