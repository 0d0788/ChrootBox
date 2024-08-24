#!/bin/bash

# Copyright (C) 2024 www.github.com/0d0788. All rights reserved.
# This script is licensed under the GPLv3+. Please see LICENSE for more information.

### chroot wrapper to make interactive sandbox env on file level.
### use this script everytime you want to enter the sandbox

## script settings
CHROOT_PATH="/chroot_env" # absolute path to the folder used by chroot as root dir
X_USER="theo" # user on the host that runs the X server (needed to copy the .Xauthority file to chroot env for GUIs)

if [ $UID != 0 ]; then
	echo "needs to run with root priveleges: quitting"
	exit 1
fi

if [ ! -d $CHROOT_PATH ]; then
	mkdir $CHROOT_PATH
	rsync -vrlHpEXog --progress /* $CHROOT_PATH \
	--exclude /home/ \
	--exclude /mnt/ \
	--exclude /proc/ \
	--exclude /run/ \
	--exclude /tmp/ \
	--exclude /boot/ \
	--exclude /dev/ \
	--exclude /sys/ \
	--exclude $CHROOT_PATH/ \
	--exclude chroot_env.sh
	mkdir $CHROOT_PATH/home &
	export new_env=1
else
	echo "$CHROOT_PATH already exists : skipping"
fi

if [ ! -d $CHROOT_PATH/proc ]; then
	mkdir $CHROOT_PATH/proc
	mount --types proc /proc $CHROOT_PATH/proc
fi

if [ ! -d $CHROOT_PATH/run ]; then
	mkdir $CHROOT_PATH/run
        mount --bind /run $CHROOT_PATH/run
	mount --make-slave $CHROOT_PATH/run
fi

if [ ! -d $CHROOT_PATH/dev ]; then
	mkdir $CHROOT_PATH/dev
	mount --rbind /dev $CHROOT_PATH/dev
	mount --make-rslave $CHROOT_PATH/dev
fi

if [ ! -d $CHROOT_PATH/sys ]; then
	mkdir $CHROOT_PATH/sys
        mount --rbind /sys $CHROOT_PATH/sys
	mount --make-rslave $CHROOT_PATH/sys
fi

if [ ! -d $CHROOT_PATH/tmp ]; then
        mkdir $CHROOT_PATH/tmp
        mount --bind /tmp $CHROOT_PATH/tmp
        mount --make-slave $CHROOT_PATH/tmp
fi

if [[ $new_env == 1 ]]; then
	# Install packages if chroot env is new
	# The package manager used here is DNF from Fedora Linux, change that if needed
	chroot $CHROOT_PATH /bin/bash -c "dnf install geany" # install geany using dnf package manager
	chroot $CHROOT_PATH /bin/bash -c "dnf install geany-themes" # install geany-themes using dnf package manager
	chroot $CHROOT_PATH /bin/bash -c "dnf install tmux" # install tmux using dnf package manager
	chroot $CHROOT_PATH /bin/bash -c "dnf install dmenu" # install dmenu using dnf package manager

	# change the PS1 of root (important if sudo -i is used)
	echo 'PS1="(chroot) ${PS1}"' >> $CHROOT_PATH/root/.bashrc

	# create user change PS1 and disable root login
	chroot $CHROOT_PATH /bin/bash -c "useradd user"
	echo 'user ALL=(ALL) NOPASSWD:ALL' > $CHROOT_PATH/etc/sudoers.d/user
	echo 'PS1="(chroot) ${PS1}"' >> $CHROOT_PATH/home/user/.bashrc
	chroot $CHROOT_PATH /bin/bash -c "passwd --lock root" # disable root (use sudo -i to get interactive root shell)

	# for X Applications
	echo 'export DISPLAY=:0' >> $CHROOT_PATH/home/user/.bashrc # set DISPLAY env variable
	cp /home/$X_USER/.Xauthority $CHROOT_PATH/home/user/ # copy the .Xauthority file to the chroot env
	chroot $CHROOT_PATH /bin/bash -c "chown user:user /home/user/.Xauthority" # correct the owner of copied .Xauthority
fi

unset new_env # unset the new_env var (not used anymore from here)

chmod -R 1777 $CHROOT_PATH/tmp/ # set the correct file permissions for $CHROOT_PATH/tmp

echo "entering chroot env..."
rm -rf /tmp/tmux* # remove old tmux temp files to avoid conflicts because of shared /tmp dir
chroot $CHROOT_PATH /bin/bash -c "su - user -c 'exec tmux new-session'" # enter chroot and launch tmux as user

# umount everything after exiting the chroot env
umount -l $CHROOT_PATH/proc && rm -rf $CHROOT_PATH/proc
umount -l $CHROOT_PATH/run && rm -rf $CHROOT_PATH/run
umount -l $CHROOT_PATH/dev{/shm,/pts,} && rm -rf $CHROOT_PATH/dev
umount -l $CHROOT_PATH/sys && rm -rf $CHROOT_PATH/sys
umount -l $CHROOT_PATH/tmp && rm -rf $CHROOT_PATH/tmp
