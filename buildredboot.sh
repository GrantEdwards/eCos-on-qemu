#!/bin/bash

set -o nounset
set -o errexit

rm -rf build-redboot
mkdir build-redboot
cd build-redboot

cat >redboot.cdl <<EOF
cdl_option CYGSEM_REDBOOT_DISK_IDE  {user_value 0}
cdl_option CYG_HAL_STARTUP {user_value GRUB}
cdl_option CYGSEM_REDBOOT_DEFAULT_NO_BOOTP {user_value 1}
cdl_option CYGDAT_REDBOOT_DEFAULT_IP_ADDR {user_value 1 "172,16,0,2"}
EOF

ecosconfig new pc_rltk8139 redboot
ecosconfig add CYGPKG_IO_ETH_DRIVERS
ecosconfig import redboot.cdl
ecosconfig tree
make
