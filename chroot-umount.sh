#!/bin/bash

source ./pkgbuild-settings.sh || exit 1

umount "${PKGBUILD_ENV_DIR}/dev/pts"
umount "${PKGBUILD_ENV_DIR}/dev/shm"
umount "${PKGBUILD_ENV_DIR}/dev"
umount "${PKGBUILD_ENV_DIR}/proc"
umount "${PKGBUILD_ENV_DIR}/sys"
