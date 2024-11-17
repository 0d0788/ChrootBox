ChrootBox
=

ChrootBox is a small wrapper script around chroot to create and enter an interactive sandbox like environment.
Useful e.g. for testing applications with many dependencies so that you can just remove the $CHROOT_PATH dir like a container image
and don't have to worry about keeping your main os clean from junk.

The chroot environment supports starting graphical X applications and a shared /tmp for file exchange.
It is possible to mount new devices (USB flash drives for example) in the chroot env. because /dev is binded to $CHROOT_PATH/dev.

Usage:
- change the value of $X_USER to the name of the home directory of the user under which the X server is running (needed for copying the correct .Xauthority file)
- Just execute the script from anywhere in the filesystem (without any arguments)
  if $CHROOT_PATH already exists in the filesystem it just enters the sandbox (execute chroot) otherwise it creates $CHROOT_PATH
- if needed change $CHROOT_PATH to something else
