#!/bin/bash

export ARCH="amd64"
export MIRROR="http://gentoo.osuosl.org"

GENTOO_BUILD="20140501"


download_stage3() {

    STAGE3="stage3-amd64-${GENTOO_BUILD}.tar.bz2"
    STAGE3_CHECKSUM="stage3-amd64-${GENTOO_BUILD}.tar.bz2.DIGESTS"

    BUILD_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64"
    STAGE3_URL="${BUILD_URL}/${STAGE3}"
    STAGE3_CHECKSUM_URL="${BUILD_URL}/${STAGE3_CHECKSUM}"

    echo "------"
    echo "Downloading stage3 for Gentoo build version ${GENTOO_BUILD}"

    [[ -d $PKGBUILD_STAGE3_DIR ]] || mkdir $PKGBUILD_STAGE3_DIR

    if [[ -f "${PKGBUILD_STAGE3_DIR}/$STAGE3" ]]; then
        echo "Stage3 ${STAGE3} already downloaded."
    else
        wget $STAGE3_URL -O "${PKGBUILD_STAGE3_DIR}/${STAGE3}"
        wget $STAGE3_CHECKSUM_URL -O "${PKGBUILD_STAGE3_DIR}/${STAGE3_CHECKSUM}"
    fi

    echo -n "Actual digest of stage3:"
    sed -ne '2p' "${PKGBUILD_STAGE3_DIR}/stage3-$ARCH-$GENTOO_BUILD.tar.bz2.DIGESTS"
    echo -n "Expected digest of stage3:"
    sha512sum "${PKGBUILD_STAGE3_DIR}/stage3-$ARCH-$GENTOO_BUILD.tar.bz2"

    diff <(sha512sum "${PKGBUILD_STAGE3_DIR}/$STAGE3" | awk '{print $1}') <(sed -ne '2p' "${PKGBUILD_STAGE3_DIR}/$STAGE3_CHECKSUM" | awk '{print $1}')
    if [ $? -eq 0 ]; then
        echo "Actual digest matches expected digests."
    else
        echo "WARNING: stage3 digest does not match expectation. Cannot continue"
        exit 1
    fi
}

download_portage_tree() {


    PORTAGE="portage-latest.tar.bz2"
    PORTAGE_URL="${MIRROR}/snapshots/${PORTAGE}"

    echo "------"
    echo "Downloading Gentoo portage tree"

    [[ -d $PKGBUILD_PORTAGE_DIR ]] || mkdir $PKGBUILD_PORTAGE_DIR

    if [[ -f "${PKGBUILD_PORTAGE_DIR}/${PORTAGE}" ]]; then
        echo "Portage tree ${PORTAGE} already downloaded."
        return
    fi

    wget $PORTAGE_URL -O "${PKGBUILD_PORTAGE_DIR}/$PORTAGE"
}

unpack_chroot() {
    echo "------"
    echo "Populating chroot ${PKGBUILD_ENV_DIR}"

    [[ -d $PKGBUILD_ENV_DIR ]] || mkdir -p $PKGBUILD_ENV_DIR

    if [[ -d "${PKGBUILD_ENV_DIR}/usr" ]]; then
        echo "Stage3 already unpacked."
    else
        echo "Unpacking stage3."
        tar -xjf $PKGBUILD_STAGE3_DIR/$STAGE3 -C $PKGBUILD_ENV_DIR
    fi

    if [[ -d "${PKGBUILD_ENV_DIR}/usr/portage" ]]; then
        echo "Portage already unpacked."
    else
        echo "Unpacking portage."
        tar -xjf $PKGBUILD_PORTAGE_DIR/$PORTAGE -C "${PKGBUILD_ENV_DIR}/usr"
    fi
}

copy_bootstrapper() {
    cp bootstrap-sabayon.sh $PKGBUILD_ENV_DIR
}

prepare_environment() {
    if ! [[ -n $BASEDIR ]]; then
        echo "BASEDIR is unset, exiting."
    fi
    CHROOT_DIR=${CHROOT_DIR:-$BASEDIR/chroots}
}

source ./pkgbuild-settings.sh || exit 1

download_stage3
download_portage_tree
unpack_chroot
