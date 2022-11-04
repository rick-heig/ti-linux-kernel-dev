#!/bin/sh
#
ARCH=$(uname -m)

config="defconfig"

build_prefix="-ti-arm64-staging-r"
branch_prefix="ti-linux-arm64-staging-"
branch_postfix=".y"
bborg_branch="5.10-arm64-staging"

#https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/Documentation/process/changes.rst?h=v5.10-rc1
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
#arm64
KERNEL_ARCH=arm64
DEBARCH=arm64
#toolchain="gcc_6_aarch64"
#toolchain="gcc_7_aarch64"
#toolchain="gcc_8_aarch64"
#toolchain="gcc_9_aarch64"
toolchain="gcc_10_aarch64"
#toolchain="gcc_11_aarch64"
#toolchain="gcc_12_aarch64"
#riscv64
#KERNEL_ARCH=riscv
#DEBARCH=riscv64
#toolchain="gcc_7_riscv64"
#toolchain="gcc_8_riscv64"
#toolchain="gcc_9_riscv64"
#toolchain="gcc_10_riscv64"
#toolchain="gcc_11_riscv64"
#toolchain="gcc_12_riscv64"

#Kernel
KERNEL_REL=5.10
KERNEL_TAG=${KERNEL_REL}.131
kernel_rt=".131-rt72"
#Kernel Build
BUILD=${build_prefix}68

#v5.X-rcX + upto SHA
#prev_KERNEL_SHA=""
#KERNEL_SHA=""

#git branch
BRANCH="${branch_prefix}${KERNEL_REL}${branch_postfix}"

DISTRO=xross

ti_git_old_release="2176e1735b744c2b002b8c86ca748483c5f7cf0c"
ti_git_new_release="f9344bef79dc600e7c3651e4f4a3c5b196614f87"

#https://git.ti.com/gitweb?p=ti-linux-kernel/ti-linux-kernel.git;a=tag;h=refs/tags/08.04.01.003
#https://git.ti.com/gitweb?p=ti-linux-kernel/ti-linux-kernel.git;a=shortlog;h=f9344bef79dc600e7c3651e4f4a3c5b196614f87

#https://git.ti.com/gitweb?p=ti-linux-kernel/ti-linux-kernel.git;a=tag;h=refs/tags/08.04.01.002
#https://git.ti.com/gitweb?p=ti-linux-kernel/ti-linux-kernel.git;a=shortlog;h=2176e1735b744c2b002b8c86ca748483c5f7cf0c

#
