ChrootBox
=

ChrootBox is a small wrapper script around chroot to create and enter an interactive sandbox like environment.
Useful e.g. for testing applications with many dependencies so that you can just remove the $CHROOT_PATH dir like a container image
and don't have to worry about keeping your main os clean from junk.

The chroot environment supports starting graphical X applications and a shared /tmp for file exchange.
It is possible to mount new devices (USB flash drives for example) in the chroot env. because /dev is binded to $CHROOT_PATH/dev.

How it works:
-
- copy /* into $CHROOT_PATH (defined in the script)
- mount (bind) everything important into $CHROOT_PATH (/proc, /run, /dev, /sys)
- mount (bind) /tmp into $CHROOT_PATH (shared /tmp for file exchange)
- install important packages in the chroot env. (editors, tmux)
- in the chroot env. create a user and lock root (further root access with sudo or sudo -i)
- export $DISPLAY env var and copy .Xauthority file from host X-server into $CHROOT_PATH/home/user to make GUIs work
- execute chroot with $CHROOT_PATH as new root and launch tmux as user ( ```chroot $CHROOT_PATH /bin/bash -c "su - user -c 'exec tmux'"``` )

Usage:
- change the value of $X_USER to the name of the home directory of the user under which the X server is running (needed for copying the correct .Xauthority file)
- Just execute the script from anywhere in the filesystem (without any arguments)
  if $CHROOT_PATH already exists in the filesystem it just enters the sandbox (execute chroot) otherwise it creates $CHROOT_PATH
- if needed change $CHROOT_PATH to something else
