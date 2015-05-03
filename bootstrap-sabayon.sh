#!/bin/bash

setup_lang() {
    export LANG=en_US
    export LANGUAGE=${LANG}
    export LC_ALL=${LANG}.UTF-8

    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
}

setup_system() {
    ln -sf ../usr/share/zoneinfo/America/Los_Angeles /etc/localtime
echo "nameserver 8.8.8.8
8.8.4.4 
2001:4860:4860::8888
2001:4860:4860::8844 " > /etc/resolv.conf  
#adds google public dns includes 2 IPv6

    # sets python 2.7 as default
    eselect python set 1
    env-update
    source /etc/profile
}

prepare_portage() {

    #emerge --sync

    echo 'MAKEOPTS="-j5"' >> /etc/portage/make.conf 

    mkdir -p /etc/portage/package.keywords
    mkdir -p /etc/portage/package.use

    echo "sys-apps/entropy ~amd64" >> /etc/portage/package.keywords/entropy
    echo "app-admin/equo ~amd64" >> /etc/portage/package.keywords/entropy

    echo "app-portage/layman git"  > /etc/portage/package.use/layman

    env-update
    source /etc/profile
}

install_layman() {
    emerge -v layman
    layman -a sabayon
    layman -S

    echo "source /var/lib/layman/make.conf" >> /etc/portage/make.conf
    env-update
    source /etc/profile
}

install_entropy() {
    emerge -vt app-admin/equo sys-apps/entropy --autounmask-write
    etc-update --automode -5
    emerge -vt app-admin/equo sys-apps/entropy
}


setup_lang
setup_system
prepare_portage
install_layman
install_entropy
