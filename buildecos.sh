#!/bin/bash

set -o nounset
set -o errexit

rm -rf build-ecos
mkdir build-ecos
cd build-ecos

cat >ecos.cdl <<EOF
cdl_option CYGHWR_HAL_I386_PC_LOAD_HIGH {user_value 1}
cdl_option CYG_HAL_STARTUP {user_value GRUB}
cdl_option CYGPKG_NET_INET6 {user_value 0}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS {user_value 1}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS_IP {user_value 172.16.0.2}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS_NETMASK {user_value 255.255.255.0}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS_BROADCAST {user_value 172.16.0.255}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS_GATEWAY {user_value 172.16.0.1}
cdl_option CYGHWR_NET_DRIVER_ETH0_ADDRS_SERVER {user_value 172.16.0.1}
cdl_option CYGSEM_HAL_DIAG_MANGLER {user_value None}
cdl_option CYGPKG_NET_BUILD_HW_TESTS {user_value 1}
cdl_option CYGPKG_NET_MEM_USAGE {user_value 0x100000}
cdl_option CYGNUM_FILEIO_NFD {user_value 64}
cdl_option CYGNUM_FILEIO_NFILE {user_value 64}
EOF

ecosconfig new pc_rltk8139 net
ecosconfig import ecos.cdl
ecosconfig tree
make

