#!/bin/bash

# a shell script to run in the Qemu PC emulator an eCos
# application that's been built with "Grub" startup mode for the
# pc_rltk8239 target.
#
# The program to be run is $1.  It runs Qemu with the no-graphics
# option and with a single serial port connected to a telnet
# server socket.
#
# An instance of the "aterm" X11 terminal emulator is started with
# telnet command to connect to that virtual serial port.
#
# TUN/TAP networking is used to create a point-to-point Ethernet link
# to the virtual machine.  The host end is 172.16.0.1, so you should
# configure the eCos build to use a static 172.16.0.x network address.
#
# The script could be modified to bridge the virtual TAP interface 
# with a physcial interface if you want to make the virtual machine
# accessible from other hosts.  Or you could start a DHCP server on 
# the TAP interface so that you don't have to build apps with static
# IP configurations.

set -o nounset
set -o errexit

do_vga=n
if [ "$1" = "--vga" ]; then
    do_vga=y
    shift
fi

function StartQemu {
  # create a TAP interface belonging to the user
  User=$USER
  TAP=tap_qemu_$$
  if [ $do_vga = y ]; then
      QEMU_GRAPHICS=""
  else
      QEMU_GRAPHICS="-nographic"
  fi
  
  sudo ip tuntap add dev $TAP mode tap user $User
  sudo ifconfig $TAP 172.16.0.1/24 promisc up
  # start the emulator using the TAP interface we created above
  qemu-system-i386 -net nic,model=rtl8139  -net tap,ifname=$TAP,script=no $QEMU_GRAPHICS $*

  # remove the TAP interface
  sudo ip tuntap del dev $TAP mode tap
  }

TEMP=${TEMP:-/tmp}

# create a bootable ISO image with Grub configured to load the program

ProgPath="$1"
Prog=$(basename "$ProgPath")
Iso=$TEMP/grub-$$.iso
Tree=$TEMP/grub-$$-tree

# we want to end up with an ISO image with this structure:
#
# /
# |-- boot
# |   `-- grub
# |       |-- menu.lst
# |       `-- stage2_eltorito
# `-- eCosApplication.elf

# create the empty directry "tree" (only has the one branch)
mkdir -p $Tree/boot/grub

# copy Grub stage2 file
cp grub_stage2_eltorito $Tree/boot/grub

# create Grub configuration file that loads program
GRUB_CONSOLE_CONFIG="\
serial --unit=0 --speed=115200
terminal --timeout=2 serial console"

if [ $do_vga = y ]; then
    GRUB_CONSOLE_CONFIG=""
fi

cat >$Tree/boot/grub/menu.lst <<EOF
$GRUB_CONSOLE_CONFIG
default 0
timeout 2
title  /$Prog
kernel /$Prog
EOF

# application goes in "root" directory, and stripping it will
# drastically speed up loading
cp $ProgPath $Tree
strip $Tree/$Prog 

# create the bootable ISO9660 image
mkisofs -quiet -R -b boot/grub/grub_stage2_eltorito -no-emul-boot \
   -boot-load-size 4 -boot-info-table -o $Iso $Tree
   
# done with the tree
rm -rf $Tree

# refresh sudo's timer because settup up tap/tun and loading kqemu 
# will use sudo
sudo -v -p "We need to run some things using sudo, so please enter your password.
Password: "

# Unless we're running in "vga" mode start a terminal that will telnet
# to the virtual machine's serial port, but it needs to wait until
# after qemu has started up.

if [ $do_vga = n ]; then
    (sleep 0.5; aterm -title "eCos Serial 0" -name "eCos Serial 0" -e telnet localhost 9876)&
    StartQemu -boot d -cdrom $Iso -serial telnet:localhost:9876,server
else
    StartQemu -boot d -cdrom $Iso
fi

# clean up
rm -rf $Iso
