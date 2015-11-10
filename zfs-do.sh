#!/bin/sh
#
# Calomel.org
#     https://calomel.org/zfs_freebsd_root_install.html
#     FreeBSD 10.2-RELEASE ZFS Root Install script
#     zfs.sh @ Version 0.19

echo "# remove any old partitions on destination drive"
umount zroot
umount /mnt
zpool destroy zroot
gpart delete -i 2 ada0
gpart delete -i 1 ada0
gpart destroy -F ada0

echo ""
echo "# Create zfs boot (512k) and a 1TB zfs root partitions"
gpart create -s gpt ada0
gpart add -a 4k -s 512k -t freebsd-boot ada0
gpart add -a 4k -s 1T -t freebsd-zfs -l disk0 ada0
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada0

echo ""
echo "# Align the Disks for 4K and create the pool"
gnop create -S 4096 /dev/gpt/disk0
zpool create -f -o altroot=/mnt -o cachefile=/var/tmp/zpool.cache zroot /dev/gpt/disk0.nop
zpool export zroot
gnop destroy /dev/gpt/disk0.nop
zpool import -o altroot=/mnt -o cachefile=/var/tmp/zpool.cache zroot

echo ""
echo "# Set the bootfs property and set options"
zpool set bootfs=zroot zroot
zpool set listsnapshots=on zroot
zpool set autoreplace=on zroot
#zpool set autoexpand=on zroot
zfs set checksum=fletcher4 zroot
zfs set compression=lz4 zroot
zfs set atime=off zroot
zfs set copies=3 zroot
#zfs set mountpoint=/ zroot

echo ""
echo "# Add swap space and apply options"
zfs create -V 1G zroot/swap
zfs set org.freebsd:swap=on zroot/swap

echo ""
echo "# Create a symlink to /home and fix some permissions"
cd /mnt/zroot ; ln -s usr/home home

echo ""
echo "# Install FreeBSD OS from *.txz memstick."
echo "# This will take a few minutes..."
cd /usr/freebsd-dist
export DESTDIR=/mnt/zroot
###### Option 1: only install a 64bit os without 32bit libs
 for file in base.txz kernel.txz doc.txz ports.txz src.txz;
###### Option 2: also include 32bit compatable libs
#for file in base.txz lib32.txz kernel.txz doc.txz ports.txz src.txz;
do (cat $file | tar --unlink -xpJf - -C ${DESTDIR:-/}); done

echo ""
echo "# Copy zpool.cache to install disk."
cp /var/tmp/zpool.cache /mnt/zroot/boot/zfs/zpool.cache

echo ""
echo "# Setup ZFS root mount and boot"
echo 'zfs_enable="YES"' >> /mnt/zroot/etc/rc.conf
echo 'zfs_load="YES"' >> /mnt/zroot/boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> /mnt/zroot/boot/loader.conf

echo ""
echo "# use gpt ids instead of gptids or disks idents"
echo 'kern.geom.label.disk_ident.enable="0"' >> /mnt/zroot/boot/loader.conf
echo 'kern.geom.label.gpt.enable="1"' >> /mnt/zroot/boot/loader.conf
echo 'kern.geom.label.gptid.enable="0"' >> /mnt/zroot/boot/loader.conf

echo ""
echo "# enable networking, pf and ssh and stop syslog from listening."
echo 'hostname="FreeBSDzfs"' >> /mnt/zroot/etc/rc.conf
echo 'ifconfig_igb0="dhcp"' >> /mnt/zroot/etc/rc.conf
echo '#ifconfig_igb0="inet 192.168.0.150 netmask 255.255.255.0 lladdr 00:11:22:33:44:55"' >> /mnt/zroot/etc/rc.conf
echo '#defaultrouter="192.168.0.1"' >> /mnt/zroot/etc/rc.conf
echo '#pf_enable="YES"' >> /mnt/zroot/etc/rc.conf
echo '#pflog_enable="YES"' >> /mnt/zroot/etc/rc.conf
echo 'sshd_enable="YES"' >> /mnt/zroot/etc/rc.conf
echo 'syslogd_flags="-ss"' >> /mnt/zroot/etc/rc.conf

echo ""
echo "# sshd, disable remote root logins."
echo 'PermitRootLogin no' >> /mnt/zroot/etc/ssh/sshd_config
echo 'PermitEmptyPasswords no' >> /mnt/zroot/etc/ssh/sshd_config

echo ""
echo "# /etc/rc.conf disable sendmail"
echo 'dumpdev="NO"' >> /mnt/zroot/etc/rc.conf
echo 'sendmail_enable="NO"' >> /mnt/zroot/etc/rc.conf
echo 'sendmail_submit_enable="NO"' >> /mnt/zroot/etc/rc.conf
echo 'sendmail_outbound_enable="NO"' >> /mnt/zroot/etc/rc.conf
echo 'sendmail_msp_queue_enable="NO"' >> /mnt/zroot/etc/rc.conf

echo ""
echo "# touch the /etc/fstab else freebsd will not boot properly"
touch /mnt/zroot/etc/fstab

sync
echo ""
echo "# Syncing... Install Done."
echo ""
echo "# Hint: poweroff , remove the USB drive and reboot the box."
echo "#       Then add a privlidged user to the 'wheel' group. You will"
echo "#       then be able to ssh in as the new user and configure the box."
echo ""
sync

#### EOF ####
