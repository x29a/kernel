#!/bin/bash
# See more info at 
# https://blog.chris007.de/compiling-a-kernel-module-on-and-for-the-raspberry-pi/

# currently running kernel version
KERNEL_VER=$(uname -r)
# path to full rpi kernel git repo
KERNEL_SRC=/root/kernel/master
# branch of kernel
KERNEL_BRANCH="rpi-4.4.y"

# prerequisites
# apt-get update && apt-get -y install git bc

# if on unofficial kernel from rpi-update (you are on your own, things are more complicated):
# rm /boot/.firmware_revision
# WANT_SYMVERS=1 rpi-update

# checkout the kernel
echo ">>> checking out repo"
read -n 1 -s
git clone https://github.com/raspberrypi/linux.git ${KERNEL_SRC}

# see following instruction on getting the right kernel version
# - http://raspberrypi.stackexchange.com/a/38991
echo ">>> calculating hash"
read -n 1 -s
HASH_ID="firmware as of"
COMMIT_HASH="$(zgrep "$HASH_ID" /usr/share/doc/raspberrypi-bootloader/changelog.Debian.gz | head -1)"
COMMIT_HASH=$(echo "$COMMIT_HASH" | sed -e "s/^.*$HASH_ID//g" | tr -d '[[:space:]]')
echo ">>> commit hash: ${COMMIT_HASH}"
read -n 1 -s

GIT_HASH_URL="https://raw.githubusercontent.com/raspberrypi/firmware/${COMMIT_HASH}/extra/git_hash"
echo ">>> git hash url: ${GIT_HASH_URL}"
read -n 1 -s

GIT_HASH=$(wget ${GIT_HASH_URL} -q -O -)
echo ">>> hash: ${GIT_HASH}"

# checkout right version
echo ">>> checkout specific branch"
read -n 1 -s
cd ${KERNEL_SRC}
git checkout -f ${KERNEL_BRANCH}

echo ">>> update branch"
read -n 1 -s
git pull origin ${KERNEL_BRANCH}

echo ">>> reset to specific commit hash"
read -n 1 -s
git reset --hard ${GIT_HASH} 

# get config of currently running kernel
echo ">>> using .config of current kernel"
read -n 1 -s
modprobe configs
zcat /proc/config.gz > ${KERNEL_SRC}/.config

# link kernel source for compilation of modules
echo ">>> linking kernel source for modules"
read -n 1 -s
ln -s ${KERNEL_SRC}/build /lib/modules/${KERNEL_VER}/build

# get symbol information from running kernel
# if on arm v7, download Module7.symvers but rename it to Module.symvers anyway
echo ">>> copy module symbol info"
read -n 1 -s
MODULE_URL="https://raw.githubusercontent.com/raspberrypi/firmware/${COMMIT_HASH}/extra/Module.symvers"
wget -q ${MODULE_URL} -O ${KERNEL_SRC}/Module.symvers
# if on rpi-update kernel
# cp /boot/Module.symvers ${KERNEL_SRC}/Module.symvers
# if installed linux-headers package
# cp /usr/src/linux-headers-${KERNEL_VER}/Module.symvers ${KERNEL_SRC}/Module.symvers

# check version in ${KERNEL_SRC}/Makefile

# prepare build
echo ">>> preparing build"
export KERNEL=kernel
read -n 1 -s
# if the next step asks for kernel parameters something is odd and highly likely things wont work. version mismatch
make oldconfig
make prepare
make scripts
make modules_prepare

echo ">>> build module"
read -n 1 -s
# to only build one path
# make path/to/file.c
# make M=path/to/module
# see: http://askubuntu.com/a/171633/323901
make M=drivers/w1/

# checkout the results and load them
modinfo drivers/w1/slaves/w1_therm.ko
rmmod w1_therm
insmod drivers/w1/slaves/w1_therm.ko
lsmod
