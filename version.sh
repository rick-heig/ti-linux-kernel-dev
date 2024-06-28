#!/bin/sh
#
ARCH=$(uname -m)

config="defconfig"

build_prefix="-ti-arm64-r"
branch_prefix="ti-linux-arm64-"
branch_postfix=".y"
bborg_branch="6.1-arm64"

#https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/Documentation/process/changes.rst?h=v6.1-rc1
#arm
#KERNEL_ARCH=arm
#DEBARCH=armhf
#toolchain="gcc_6_arm"
#toolchain="gcc_7_arm"
#toolchain="gcc_8_arm"
#toolchain="gcc_9_arm"
#toolchain="gcc_10_arm"
#toolchain="gcc_11_arm"
#toolchain="gcc_12_arm"
#toolchain="gcc_13_arm"
#arm64
KERNEL_ARCH=arm64
DEBARCH=arm64
#toolchain="gcc_6_aarch64"
#toolchain="gcc_7_aarch64"
#toolchain="gcc_8_aarch64"
#toolchain="gcc_9_aarch64"
#toolchain="gcc_10_aarch64"
#toolchain="gcc_11_aarch64"
toolchain="gcc_12_aarch64"
#toolchain="gcc_13_aarch64"
#riscv64
#KERNEL_ARCH=riscv
#DEBARCH=riscv64
#toolchain="gcc_7_riscv64"
#toolchain="gcc_8_riscv64"
#toolchain="gcc_9_riscv64"
#toolchain="gcc_10_riscv64"
#toolchain="gcc_11_riscv64"
#toolchain="gcc_12_riscv64"
#toolchain="gcc_13_riscv64"

#Kernel
KERNEL_REL=6.1
KERNEL_TAG=${KERNEL_REL}.83
kernel_rt=".83-rt28"
#Kernel Build
BUILD=${build_prefix}59.1

#v6.X-rcX + upto SHA
#prev_KERNEL_SHA=""
#KERNEL_SHA=""

#git branch
BRANCH="${branch_prefix}${KERNEL_REL}${branch_postfix}"

DISTRO=xross

ti_git_old_release="2e423244f8c09173a344e7069f0fe2bdf26cccee"
ti_git_new_release="c1c2f1971fbf6ddad93a8c94314fe8221e7aa6be"
TISDK="09.02.00.010"

#
