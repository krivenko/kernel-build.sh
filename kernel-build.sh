#!/bin/bash

SRC_DIR="/usr/src"
CONFIGS_DIR="/etc/kernel"
BOOT_DIR="/boot"
MAKECONF="/etc/portage/make.conf"

UEFI_BOOTNUM=0000
UEFI_LABEL="Gentoo Linux"
BOOT_DEVICE="/dev/nvme0n1"
BOOT_PARTITION_NUM=1

HOSTNAME=$(hostname)
SCRIPT_NAME=$(basename $0)

printusage() {
        echo "Usage:"
        echo "${SCRIPT_NAME} saveconfig"
        echo "${SCRIPT_NAME} loadconfig [kernel_version]"
        echo "${SCRIPT_NAME} configure"
        echo "${SCRIPT_NAME} build"
        echo "${SCRIPT_NAME} install"
        echo "${SCRIPT_NAME} oldconfig"
        echo "${SCRIPT_NAME} minorupdate"
}

find_best_version() {
        local version_regexp="(.*)-([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{1,2})(-([^r][^\-]*))?(-(r[0-9]+))?"

        if [[ $1 =~ $version_regexp ]]; then
                local hostname=${BASH_REMATCH[1]}
                local ver_major=${BASH_REMATCH[2]}
                local ver_minor=${BASH_REMATCH[3]}
                local ver_patchlevel=${BASH_REMATCH[4]}
                local variant=${BASH_REMATCH[6]}
                local revision=${BASH_REMATCH[8]}
        else
                exit 1
        fi

        local configs=""
        for c in $(cd ${CONFIGS_DIR}; ls *.config); do
                c=${c%.config}
                if [[ ${c} =~ $version_regexp ]]; then
                        if [[ ${BASH_REMATCH[1]} == "${hostname}" ]] && [[ ${BASH_REMATCH[6]} == "${variant}" ]]
                        then
                                if      (( ${BASH_REMATCH[2]} < ${ver_major} )) ||
                                        (( ${BASH_REMATCH[2]} == ${ver_major} && ${BASH_REMATCH[3]} < ${ver_minor} )) ||
                                        (( ${BASH_REMATCH[2]} == ${ver_major} && ${BASH_REMATCH[3]} == ${ver_minor} && ${BASH_REMATCH[4]} <= ${ver_patchlevel} ))
                                then
                                        configs+="$c\n"
                                fi
                        fi
                fi
        done
        echo $(echo -e $configs | sort -V | tail -n1)
}

saveconfig() {
        CURRENT_CONFIG="${SRC_DIR}/linux/.config"
        if [ ! -f $CURRENT_CONFIG ]
        then
                echo "Cannot find $CURRENT_CONFIG. Have you configured the current kernel?"
                exit 2
        fi

        CURRENT_VERSION="${HOSTNAME}-$(cd ${SRC_DIR}/linux; make kernelversion)"

        SRC_CONFIG="${SRC_DIR}/linux/.config"
        DST_CONFIG="${CONFIGS_DIR}/${CURRENT_VERSION}.config"

        echo "Copying ${SRC_CONFIG} to ${DST_CONFIG} ..."
        cp -i "${SRC_CONFIG}" "${DST_CONFIG}"
}

loadconfig() {
        CURRENT_VERSION="${HOSTNAME}-$(cd ${SRC_DIR}/linux; make kernelversion)"
        DST_CONFIG="${SRC_DIR}/linux/.config"

        if [ ! -z $1 ]  # Precise version specified
        then
                SRC_CONFIG="${CONFIGS_DIR}/$1.config"
                if [ ! -f "${SRC_CONFIG}" ]
                then
                        echo "Cannot find $SRC_CONFIG"
                        exit 3
                fi
        else    # The best available version

                # Exact match
                if [ -f "${CONFIGS_DIR}/${CURRENT_VERSION}.config" ]; then
                        BEST_VERSION=${CURRENT_VERSION}
                else    # Heuristics
                        BEST_VERSION=$(find_best_version ${CURRENT_VERSION})
                fi
                if [ -z "${BEST_VERSION}" ]; then
                        echo "Cannot find a suitable saved version."
                        exit 4
                else
                        echo "The best available saved version is ${BEST_VERSION}"
                        SRC_CONFIG="${CONFIGS_DIR}/${BEST_VERSION}.config"
                fi
        fi

        echo "Copying ${SRC_CONFIG} to ${DST_CONFIG} ..."
        cp -i "${SRC_CONFIG}" "${DST_CONFIG}"
}

configure(){
        pushd "${SRC_DIR}/linux"
        if [ -z $DISPLAY ]; then
                make menuconfig
        else
                make xconfig
        fi
        popd
}

oldconfig(){
        pushd "${SRC_DIR}/linux"
        make oldconfig
        popd
}

build(){
        CURRENT_CONFIG="${SRC_DIR}/linux/.config"
        if [ ! -f $CURRENT_CONFIG ]
        then
                echo "Cannot find $CURRENT_CONFIG. Starting configuration ..."
                configure
        fi

        source $MAKECONF
        echo "Make options to build the kernel: ${MAKEOPTS}"

        pushd "${SRC_DIR}/linux"
        make $MAKEOPTS
        popd
}

install(){

        # Mount boot partition if needed
        mount "${BOOT_DIR}"

        pushd "${SRC_DIR}/linux"

        V=$(make kernelversion)
        CURRENT_VERSION="${HOSTNAME}-${V}"
        make modules_install
        depmod --all

        # Install a new kernel and System.map
        cp -i System.map "${BOOT_DIR}/System.map-${CURRENT_VERSION}"
        cp -i "arch/$(uname -m)/boot/bzImage" "${BOOT_DIR}/kernel-${CURRENT_VERSION}"

        popd

        #pushd "${BOOT_DIR}"
        #cp -f "kernel-${CURRENT_VERSION}" kernel
        #cp -f "System.map-${CURRENT_VERSION}" System.map
        #popd

        umount -l "${BOOT_DIR}"

        # Update UEFI record
        efibootmgr -B -b ${UEFI_BOOTNUM} -d ${BOOT_DEVICE} -q
        efibootmgr -c -b ${UEFI_BOOTNUM} -d ${BOOT_DEVICE} -p ${BOOT_PARTITION_NUM} -e 3 \
                   -L "${UEFI_LABEL} ${V}" -l "\\kernel-${CURRENT_VERSION}"

        # Rebuild kernel modules
        emerge -av1 @module-rebuild
}

minorupdate(){
        loadconfig
        oldconfig
        build
        install
        saveconfig
}

case "$1" in

        "saveconfig" )
        saveconfig
        ;;

        "loadconfig" )
        loadconfig "$2"
        ;;

        "configure" )
        configure
        ;;

        "build" )
        build
        ;;

        "install" )
        install
        ;;

        "oldconfig" )
        oldconfig
        ;;

        "minorupdate" )
        minorupdate
        ;;

        * )
        echo "Invalid command: $1"
        printusage
        exit 1
        ;;
esac

