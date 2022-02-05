#!/bin/bash -e
#
# Copyright (c) 2009-2021 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Split out, so build_kernel.sh and build_deb.sh can share..

shopt -s nullglob

. ${DIR}/version.sh
if [ -f ${DIR}/system.sh ] ; then
	. ${DIR}/system.sh
fi
git_bin=$(which git)
#git hard requirements:
#git: --no-edit

git="${git_bin} am"
#git_patchset="git://git.ti.com/ti-linux-kernel/ti-linux-kernel.git"
git_patchset="https://github.com/RobertCNelson/ti-linux-kernel.git"
#git_opts

if [ "${RUN_BISECT}" ] ; then
	git="${git_bin} apply"
fi

echo "Starting patch.sh"

git_add () {
	${git_bin} add .
	${git_bin} commit -a -m 'testing patchset'
}

start_cleanup () {
	git="${git_bin} am --whitespace=fix"
}

cleanup () {
	if [ "${number}" ] ; then
		if [ "x${wdir}" = "x" ] ; then
			${git_bin} format-patch -${number} -o ${DIR}/patches/
		else
			if [ ! -d ${DIR}/patches/${wdir}/ ] ; then
				mkdir -p ${DIR}/patches/${wdir}/
			fi
			${git_bin} format-patch -${number} -o ${DIR}/patches/${wdir}/
			unset wdir
		fi
	fi
	exit 2
}

dir () {
	wdir="$1"
	if [ -d "${DIR}/patches/$wdir" ]; then
		echo "dir: $wdir"

		if [ "x${regenerate}" = "xenable" ] ; then
			start_cleanup
		fi

		number=
		for p in "${DIR}/patches/$wdir/"*.patch; do
			${git} "$p"
			number=$(( $number + 1 ))
		done

		if [ "x${regenerate}" = "xenable" ] ; then
			cleanup
		fi
	fi
	unset wdir
}

cherrypick () {
	if [ ! -d ../patches/${cherrypick_dir} ] ; then
		mkdir -p ../patches/${cherrypick_dir}
	fi
	${git_bin} format-patch -1 ${SHA} --start-number ${num} -o ../patches/${cherrypick_dir}
	num=$(($num+1))
}

external_git () {
	git_tag="ti-linux-${KERNEL_REL}.y"
	echo "pulling: [${git_patchset} ${git_tag}]"
	${git_bin} pull --no-edit ${git_patchset} ${git_tag}
	top_of_branch=$(${git_bin} describe)
	if [ ! "x${ti_git_post}" = "x" ] ; then
		${git_bin} checkout master -f
		test_for_branch=$(${git_bin} branch --list "v${KERNEL_TAG}${BUILD}")
		if [ "x${test_for_branch}" != "x" ] ; then
			${git_bin} branch "v${KERNEL_TAG}${BUILD}" -D
		fi
		${git_bin} checkout ${ti_git_post} -b v${KERNEL_TAG}${BUILD} -f
		current_git=$(${git_bin} describe)
		echo "${current_git}"

		if [ ! "x${top_of_branch}" = "x${current_git}" ] ; then
			echo "INFO: external git repo has updates..."
		fi
	else
		echo "${top_of_branch}"
	fi
	#exit 2
}

aufs_fail () {
	echo "aufs failed"
	exit 2
}

aufs () {
	#https://github.com/sfjro/aufs5-standalone/tree/aufs5.10.82
	aufs_prefix="aufs5-"
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		KERNEL_REL=5.10.82
		wget https://raw.githubusercontent.com/sfjro/${aufs_prefix}standalone/aufs${KERNEL_REL}/${aufs_prefix}kbuild.patch
		patch -p1 < ${aufs_prefix}kbuild.patch || aufs_fail
		rm -rf ${aufs_prefix}kbuild.patch
		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs-kbuild' -s

		wget https://raw.githubusercontent.com/sfjro/${aufs_prefix}standalone/aufs${KERNEL_REL}/${aufs_prefix}base.patch
		patch -p1 < ${aufs_prefix}base.patch || aufs_fail
		rm -rf ${aufs_prefix}base.patch
		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs-base' -s

		wget https://raw.githubusercontent.com/sfjro/${aufs_prefix}standalone/aufs${KERNEL_REL}/${aufs_prefix}mmap.patch
		patch -p1 < ${aufs_prefix}mmap.patch || aufs_fail
		rm -rf ${aufs_prefix}mmap.patch
		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs-mmap' -s

		wget https://raw.githubusercontent.com/sfjro/${aufs_prefix}standalone/aufs${KERNEL_REL}/${aufs_prefix}standalone.patch
		patch -p1 < ${aufs_prefix}standalone.patch || aufs_fail
		rm -rf ${aufs_prefix}standalone.patch
		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs-standalone' -s

		${git_bin} format-patch -4 -o ../patches/aufs/

		cd ../
		if [ ! -d ./${aufs_prefix}standalone ] ; then
			${git_bin} clone -b aufs${KERNEL_REL} https://github.com/sfjro/${aufs_prefix}standalone --depth=1
			cd ./${aufs_prefix}standalone/
				aufs_hash=$(git rev-parse HEAD)
			cd -
		else
			rm -rf ./${aufs_prefix}standalone || true
			${git_bin} clone -b aufs${KERNEL_REL} https://github.com/sfjro/${aufs_prefix}standalone --depth=1
			cd ./${aufs_prefix}standalone/
				aufs_hash=$(git rev-parse HEAD)
			cd -
		fi
		cd ./KERNEL/
		KERNEL_REL=5.10

		cp -v ../${aufs_prefix}standalone/Documentation/ABI/testing/*aufs ./Documentation/ABI/testing/
		mkdir -p ./Documentation/filesystems/aufs/
		cp -rv ../${aufs_prefix}standalone/Documentation/filesystems/aufs/* ./Documentation/filesystems/aufs/
		mkdir -p ./fs/aufs/
		cp -v ../${aufs_prefix}standalone/fs/aufs/* ./fs/aufs/
		cp -v ../${aufs_prefix}standalone/include/uapi/linux/aufs_type.h ./include/uapi/linux/

		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs' -m "https://github.com/sfjro/${aufs_prefix}standalone/commit/${aufs_hash}" -s

		wget https://raw.githubusercontent.com/sfjro/${aufs_prefix}standalone/aufs${KERNEL_REL}/rt.patch
		patch -p1 < rt.patch || aufs_fail
		rm -rf rt.patch
		${git_bin} add .
		${git_bin} commit -a -m 'merge: aufs-rt' -s

		${git_bin} format-patch -6 -o ../patches/aufs/
		echo "AUFS: https://github.com/sfjro/${aufs_prefix}standalone/commit/${aufs_hash}" > ../patches/git/AUFS

		rm -rf ../${aufs_prefix}standalone/ || true

		${git_bin} reset --hard HEAD~6

		start_cleanup

		${git} "${DIR}/patches/aufs/0001-merge-aufs-kbuild.patch"
		${git} "${DIR}/patches/aufs/0002-merge-aufs-base.patch"
		${git} "${DIR}/patches/aufs/0003-merge-aufs-mmap.patch"
		${git} "${DIR}/patches/aufs/0004-merge-aufs-standalone.patch"
		${git} "${DIR}/patches/aufs/0005-merge-aufs.patch"
		${git} "${DIR}/patches/aufs/0006-merge-aufs-rt.patch"

		wdir="aufs"
		number=6
		cleanup
	fi

	dir 'aufs'
}

wpanusb () {
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		cd ../
		if [ ! -d ./wpanusb ] ; then
			${git_bin} clone https://github.com/statropy/wpanusb --depth=1
			cd ./wpanusb
				wpanusb_hash=$(git rev-parse HEAD)
			cd -
		else
			rm -rf ./wpanusb || true
			${git_bin} clone https://github.com/statropy/wpanusb --depth=1
			cd ./wpanusb
				wpanusb_hash=$(git rev-parse HEAD)
			cd -
		fi

		cd ./KERNEL/

		cp -v ../wpanusb/wpanusb.h drivers/net/ieee802154/
		cp -v ../wpanusb/wpanusb.c drivers/net/ieee802154/

		${git_bin} add .
		${git_bin} commit -a -m 'merge: wpanusb: https://github.com/statropy/wpanusb' -m "https://github.com/statropy/wpanusb/commit/${wpanusb_hash}" -s
		${git_bin} format-patch -1 -o ../patches/wpanusb/
		echo "WPANUSB: https://github.com/statropy/wpanusb/commit/${wpanusb_hash}" > ../patches/git/WPANUSB

		rm -rf ../wpanusb/ || true

		${git_bin} reset --hard HEAD~1

		start_cleanup

		${git} "${DIR}/patches/wpanusb/0001-merge-wpanusb-https-github.com-statropy-wpanusb.patch"

		wdir="wpanusb"
		number=1
		cleanup

		exit 2
	fi
	dir 'wpanusb'
}

bcfserial () {
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		cd ../
		if [ ! -d ./bcfserial ] ; then
			${git_bin} clone https://github.com/statropy/bcfserial --depth=1
			cd ./bcfserial
				bcfserial_hash=$(git rev-parse HEAD)
			cd -
		else
			rm -rf ./bcfserial || true
			${git_bin} clone https://github.com/statropy/bcfserial --depth=1
			cd ./wpanusb
				bcfserial_hash=$(git rev-parse HEAD)
			cd -
		fi

		cd ./KERNEL/

		cp -v ../bcfserial/bcfserial.c drivers/net/ieee802154/

		${git_bin} add .
		${git_bin} commit -a -m 'merge: bcfserial: https://github.com/statropy/bcfserial' -m "https://github.com/statropy/bcfserial/commit/${bcfserial_hash}" -s
		${git_bin} format-patch -1 -o ../patches/bcfserial/
		echo "BCFSERIAL: https://github.com/statropy/bcfserial/commit/${bcfserial_hash}" > ../patches/git/BCFSERIAL

		rm -rf ../bcfserial/ || true

		${git_bin} reset --hard HEAD~1

		start_cleanup

		${git} "${DIR}/patches/bcfserial/0001-merge-bcfserial-https-github.com-statropy-bcfserial.patch"

		wdir="bcfserial"
		number=1
		cleanup

		exit 2
	fi
	dir 'bcfserial'
}

ksmbd () {
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		cd ../
		if [ ! -d ./ksmbd ] ; then
			${git_bin} clone https://github.com/cifsd-team/ksmbd --depth=1
			cd ./ksmbd
				ksmbd_hash=$(git rev-parse HEAD)
				rm -rf .git || true
			cd -
		else
			rm -rf ./ksmbd || true
			${git_bin} clone https://github.com/cifsd-team/ksmbd --depth=1
			cd ./ksmbd
				ksmbd_hash=$(git rev-parse HEAD)
				rm -rf .git || true
			cd -
		fi

		cd ./KERNEL/

		mkdir -p ./fs/ksmbd/
		cp -rv ../ksmbd/* fs/ksmbd/

		${git_bin} add .
		${git_bin} commit -a -m 'merge: ksmbd: https://github.com/cifsd-team/ksmbd' -m "https://github.com/cifsd-team/ksmbd/commit/${ksmbd_hash}" -s
		${git_bin} format-patch -1 -o ../patches/ksmbd/
		echo "KSMBD: https://github.com/cifsd-team/ksmbd/commit/${ksmbd_hash}" > ../patches/git/KSMBD

		rm -rf ../ksmbd/ || true

		${git_bin} reset --hard HEAD~1

		start_cleanup

		${git} "${DIR}/patches/ksmbd/0001-merge-ksmbd-https-github.com-cifsd-team-ksmbd.patch"

		wdir="ksmbd"
		number=1
		cleanup

		exit 2
	fi
	dir 'ksmbd'
}

rt_cleanup () {
	echo "rt: needs fixup"
	exit 2
}

rt () {
	rt_patch="${KERNEL_REL}${kernel_rt}"

	#${git_bin} revert --no-edit xyz

	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		wget -c https://www.kernel.org/pub/linux/kernel/projects/rt/${KERNEL_REL}/older/patch-${rt_patch}.patch.xz
		xzcat patch-${rt_patch}.patch.xz | patch -p1 || rt_cleanup
		rm -f patch-${rt_patch}.patch.xz
		rm -f localversion-rt
		${git_bin} add .
		${git_bin} commit -a -m 'merge: CONFIG_PREEMPT_RT Patch Set' -m "patch-${rt_patch}.patch.xz" -s
		${git_bin} format-patch -1 -o ../patches/rt/
		echo "RT: patch-${rt_patch}.patch.xz" > ../patches/git/RT

		exit 2
	fi

	dir 'rt'
}

wireless_regdb () {
	#https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then

		cd ../
		if [ ! -d ./wireless-regdb ] ; then
			${git_bin} clone git://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git --depth=1
			cd ./wireless-regdb
				wireless_regdb_hash=$(git rev-parse HEAD)
			cd -
		else
			rm -rf ./wireless-regdb || true
			${git_bin} clone git://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git --depth=1
			cd ./wireless-regdb
				wireless_regdb_hash=$(git rev-parse HEAD)
			cd -
		fi
		cd ./KERNEL/

		mkdir -p ./firmware/ || true
		cp -v ../wireless-regdb/regulatory.db ./firmware/
		cp -v ../wireless-regdb/regulatory.db.p7s ./firmware/
		${git_bin} add -f ./firmware/regulatory.*
		${git_bin} commit -a -m 'Add wireless-regdb regulatory database file' -m "https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/commit/?id=${wireless_regdb_hash}" -s

		${git_bin} format-patch -1 -o ../patches/wireless_regdb/
		echo "WIRELESS_REGDB: https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/commit/?id=${wireless_regdb_hash}" > ../patches/git/WIRELESS_REGDB

		rm -rf ../wireless-regdb/ || true

		${git_bin} reset --hard HEAD^

		start_cleanup

		${git} "${DIR}/patches/wireless_regdb/0001-Add-wireless-regdb-regulatory-database-file.patch"

		wdir="wireless_regdb"
		number=1
		cleanup
	fi

	dir 'wireless_regdb'
}

next_dtbs () {
	dir 'drivers/k3_j72xx_bandgap'
}

cleanup_dts_builds () {
	rm -rf arch/arm64/boot/dts/ti/modules.order || true
	rm -rf arch/arm64/boot/dts/ti/.*cmd || true
	rm -rf arch/arm64/boot/dts/ti/.*tmp || true
	rm -rf arch/arm64/boot/dts/ti/*dtb || true
	rm -rf arch/arm64/boot/dts/ti/*dtbo || true
}

dtb_makefile_append () {
	echo "dtb-\$(CONFIG_ARCH_K3) += $device" >> arch/arm64/boot/dts/ti/Makefile
}

beagleboard_dtbs () {
	branch="v5.10.x-ti-arm64"
	https_repo="https://github.com/beagleboard/BeagleBoard-DeviceTrees"
	work_dir="BeagleBoard-DeviceTrees"
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		cd ../
		if [ ! -d ./${work_dir} ] ; then
			${git_bin} clone -b ${branch} ${https_repo} --depth=1
			cd ./${work_dir}
				git_hash=$(git rev-parse HEAD)
			cd -
		else
			rm -rf ./${work_dir} || true
			${git_bin} clone -b ${branch} ${https_repo} --depth=1
			cd ./${work_dir}
				git_hash=$(git rev-parse HEAD)
			cd -
		fi
		cd ./KERNEL/

		cleanup_dts_builds
		rm -rf arch/arm64/boot/dts/ti/overlays/ || true

		mkdir -p arch/arm64/boot/dts/ti/overlays/
		cp -vr ../${work_dir}/src/arm64/* arch/arm64/boot/dts/ti/
		cp -vr ../${work_dir}/include/dt-bindings/* ./include/dt-bindings/

		device="k3-j721e-beagleboneai64.dtb" ; dtb_makefile_append

		${git_bin} add -f arch/arm64/boot/dts/ti/
		${git_bin} add -f include/dt-bindings/
		${git_bin} commit -a -m "Add BeagleBoard.org Device Tree Changes" -m "${https_repo}/tree/${branch}" -m "${https_repo}/commit/${git_hash}" -s
		${git_bin} format-patch -1 -o ../patches/soc/ti/beagleboard_dtbs/
		echo "BBDTBS: ${https_repo}/commit/${git_hash}" > ../patches/git/BBDTBS

		rm -rf ../${work_dir}/ || true

		${git_bin} reset --hard HEAD^

		start_cleanup

		${git} "${DIR}/patches/soc/ti/beagleboard_dtbs/0001-Add-BeagleBoard.org-Device-Tree-Changes.patch"

		wdir="soc/ti/beagleboard_dtbs"
		number=1
		cleanup
	fi

	dir 'soc/ti/beagleboard_dtbs'
}

local_patch () {
	echo "dir: dir"
	${git} "${DIR}/patches/dir/0001-patch.patch"
}

external_git
aufs
wpanusb
bcfserial
ksmbd
#rt
wireless_regdb
next_dtbs
beagleboard_dtbs
#local_patch

pre_backports () {
	echo "dir: backports/${subsystem}"

	cd ~/linux-src/
	${git_bin} pull --no-edit https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git master
	${git_bin} pull --no-edit https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git master --tags
	${git_bin} pull --no-edit https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git master --tags
	if [ ! "x${backport_tag}" = "x" ] ; then
		${git_bin} checkout ${backport_tag} -b tmp
	fi
	cd -
}

post_backports () {
	if [ ! "x${backport_tag}" = "x" ] ; then
		cd ~/linux-src/
		${git_bin} checkout master -f ; ${git_bin} branch -D tmp
		cd -
	fi

	rm -f arch/arm/boot/dts/overlays/*.dtbo || true
	${git_bin} add .
	${git_bin} commit -a -m "backports: ${subsystem}: from: linux.git" -m "Reference: ${backport_tag}" -s
	if [ ! -d ../patches/backports/${subsystem}/ ] ; then
		mkdir -p ../patches/backports/${subsystem}/
	fi
	${git_bin} format-patch -1 -o ../patches/backports/${subsystem}/
}

patch_backports (){
	echo "dir: backports/${subsystem}"
	${git} "${DIR}/patches/backports/${subsystem}/0001-backports-${subsystem}-from-linux.git.patch"
}

backports () {
	backport_tag="v5.10.98"

	subsystem="iio"
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		pre_backports

		cp -rv ~/linux-src/include/linux/iio/* ./include/linux/iio/
		cp -rv ~/linux-src/include/uapi/linux/iio/* ./include/uapi/linux/iio/
		cp -rv ~/linux-src/drivers/iio/* ./drivers/iio/
		cp -rv ~/linux-src/drivers/staging/iio/* ./drivers/staging/iio/

		post_backports
		exit 2
	else
		patch_backports
	fi

	backport_tag="v5.15.21"

	subsystem="pinmux"
	#regenerate="enable"
	if [ "x${regenerate}" = "xenable" ] ; then
		pre_backports

		cp -v ~/linux-src/drivers/pinctrl/pinmux.c ./drivers/pinctrl/
		cp -v ~/linux-src/drivers/pinctrl/pinmux.h ./drivers/pinctrl/

		post_backports
		exit 2
	else
		patch_backports
	fi
}

drivers () {
	#https://github.com/raspberrypi/linux/branches
	#exit 2
	dir 'RPi'
	dir 'drivers/spi'
	dir 'drivers/eqep'
	dir 'mikrobus'
	#dir 'fixes'
	#${git} "${DIR}/patches/fixes/0001-fix-pcie.patch"
	${git} "${DIR}/patches/fixes/0002-v2-usb-gadget-composite-Fix-null-pointer-exception.patch"
	dir 'tusb322'
	dir 'boris'
	dir 'dma-buff'
}

###
backports
drivers

packaging () {
	do_backport="enable"
	if [ "x${do_backport}" = "xenable" ] ; then
		backport_tag="v5.16.7"

		subsystem="bindeb-pkg"
		#regenerate="enable"
		if [ "x${regenerate}" = "xenable" ] ; then
			pre_backports

			cp -v ~/linux-src/scripts/package/* ./scripts/package/

			post_backports
			exit 2
		else
			patch_backports
		fi
	fi

	${git} "${DIR}/patches/backports/bindeb-pkg/0002-builddeb-Install-our-dtbs-under-boot-dtbs-version.patch"
	${git} "${DIR}/patches/backports/bindeb-pkg/0003-builddeb-copy-arm64-boot-Image-to-boot.patch"
}

packaging
echo "patch.sh ran successfully"
