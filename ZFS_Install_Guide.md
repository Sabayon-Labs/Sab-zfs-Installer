This tutorial will show you how to install Funtoo on ZFS (rootfs). This tutorial is meant to be an "overlay" over the [Regular Funtoo Installation](http://www.funtoo.org/Funtoo_Linux_Installation "Funtoo Linux Installation"). Follow the normal installation and only use this guide for steps 2, 3, and 8.

### Introduction to ZFS

Since ZFS is a new technology for Linux, it can be helpful to understand some of its benefits, particularly in comparison to BTRFS, another popular next-generation Linux filesystem:

*   On Linux, the ZFS code can be updated independently of the kernel to obtain the latest fixes. btrfs is exclusive to Linux and you need to build the latest kernel sources to get the latest fixes.

*   ZFS is supported on multiple platforms. The platforms with the best support are Solaris, FreeBSD and Linux. Other platforms with varying degrees of support are NetBSD, Mac OS X and Windows. btrfs is exclusive to Linux.

*   ZFS has the Adaptive Replacement Cache replacement algorithm while btrfs uses the Linux kernel's Last Recently Used replacement algorithm. The former often has an overwhelmingly superior hit rate, which means fewer disk accesses.

*   ZFS has the ZFS Intent Log and SLOG devices, which accelerates small synchronous write performance.

*   ZFS handles internal fragmentation gracefully, such that you can fill it until 100%. Internal fragmentation in btrfs can make btrfs think it is full at 10%. Btrfs has no automatic rebalancing code, so it requires a manual rebalance to correct it.

*   ZFS has raidz, which is like RAID 5/6 (or a hypothetical RAID 7 that supports 3 parity disks), except it does not suffer from the RAID write hole issue thanks to its use of CoW and a variable stripe size. btrfs gained integrated RAID 5/6 functionality in Linux 3.9\. However, its implementation uses a stripe cache that can only partially mitigate the effect of the RAID write hole.

*   ZFS send/receive implementation supports incremental update when doing backups. btrfs' send/receive implementation requires sending the entire snapshot.

*   ZFS supports data deduplication, which is a memory hog and only works well for specialized workloads. btrfs has no equivalent.

*   ZFS datasets have a hierarchical namespace while btrfs subvolumes have a flat namespace.

*   ZFS has the ability to create virtual block devices called zvols in its namespace. btrfs has no equivalent and must rely on the loop device for this functionality, which is cumbersome.

The only area where btrfs is ahead of ZFS is in the area of small file efficiency. btrfs supports a feature called block suballocation, which enables it to store small files far more efficiently than ZFS. It is possible to use another filesystem (e.g. reiserfs) on top of a ZFS zvol to obtain similar benefits (with arguably better data integrity) when dealing with many small files (e.g. the portage tree).

For a quick tour of ZFS and have a big picture of its common operations you can consult the page [ZFS Fun](http://www.funtoo.org/ZFS_Fun "ZFS Fun").

### Disclaimers

<div>

<div>Warning</div>

This guide is a work in progress. Expect some quirks.

</div>

<div>

<div>Important</div>

**Since ZFS was really designed for 64 bit systems, we are only recommending and supporting 64 bit platforms and installations. We will not be supporting 32 bit platforms**!

</div>

## Downloading the ISO (With ZFS)

In order for us to install Funtoo on ZFS, you will need an environment that already provides the ZFS tools. Therefore we will download a customized version of System Rescue CD with ZFS included.

<pre>Name: sysresccd-4.2.0_zfs_0.6.2.iso  (545 MB)
Release Date: 2014-02-25
md5sum 01f4e6929247d54db77ab7be4d156d85
</pre>

**undefined**

## Creating a bootable USB from ISO (From a Linux Environment)

After you download the iso, you can do the following steps to create a bootable USB:

<pre>Make a temporary directory
# mkdir /tmp/loop

Mount the iso
# mount -o ro,loop /root/sysresccd-4.2.0_zfs_0.6.2.iso /tmp/loop

Run the usb installer
# /tmp/loop/usb_inst.sh
</pre>

That should be all you need to do to get your flash drive working.

## Booting the ISO

<div>

<div>Warning</div>

**When booting into the ISO, Make sure that you select the "Alternate 64 bit kernel (altker64)". The ZFS modules have been built specifically for this kernel rather than the standard kernel. If you select a different kernel, you will get a fail to load module stack error message.**

</div>

## Creating partitions

There are two ways to partition your disk: You can use your entire drive and let ZFS automatically partition it for you, or you can do it manually.

We will be showing you how to partition it **manually** because if you partition it manually you get to create your own layout, you get to have your own separate /boot partition (Which is nice since not every bootloader supports booting from ZFS pools), and you get to boot into RAID10, RAID5 (RAIDZ) pools and any other layouts due to you having a separate /boot partition.

#### gdisk (GPT Style)

**A Fresh Start**:

First lets make sure that the disk is completely wiped from any previous disk labels and partitions. We will also assume that <tt>/dev/sda</tt> is the target drive.

<pre># sgdisk -Z /dev/sda
</pre>

<div>

<div>Warning</div>

This is a destructive operation and the program will not ask you for confirmation! Make sure you really don't want anything on this disk.

</div>

Now that we have a clean drive, we will create the new layout.

First open up the application:

<pre># gdisk /dev/sda
</pre>

**Create Partition 1** (boot):

<pre>Command: n ↵
Partition Number: ↵
First sector: ↵
Last sector: +250M ↵
Hex Code: ↵
</pre>

**Create Partition 2** (BIOS Boot Partition):

<pre>Command: n ↵
Partition Number: ↵
First sector: ↵
Last sector: +32M ↵
Hex Code: EF02 ↵
</pre>

**Create Partition 3** (ZFS):

<pre>Command: n ↵
Partition Number: ↵
First sector: ↵
Last sector: ↵
Hex Code: bf00 ↵

Command: p ↵

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048          514047   250.0 MiB   8300  Linux filesystem
   2          514048          579583   32.0 MiB    EF02  BIOS boot partition
   3          579584      1953525134   931.2 GiB   BF00  Solaris root

Command: w ↵
</pre>

### Format your /boot partition

<pre># mkfs.ext2 -m 1 /dev/sda1
</pre>

### Create the zpool

We will first create the pool. The pool will be named `tank`. Feel free to name your pool as you want. We will use `ashift=12` option which is used for a hard drives with a 4096 sector size.

<pre>#   zpool create -f -o ashift=12 -o cachefile=/tmp/zpool.cache -O normalization=formD -m none -R /mnt/funtoo tank /dev/sda3 </pre>

### Create the zfs datasets

We will now create some datasets. For this installation, we will create a small but future proof amount of datasets. We will have a dataset for the OS (/), and your swap. We will also show you how to create some optional datasets as examples ones: `/home`, `/usr/src`, and `/usr/portage`.

<pre>Create some empty containers for organization purposes, and make the dataset that will hold /
# zfs create -p tank/funtoo
# zfs create -o mountpoint=/ tank/funtoo/root

Optional, but recommended datasets: /home
# zfs create -o mountpoint=/home tank/funtoo/home

Optional datasets: /usr/src, /usr/portage/{distfiles,packages}
# zfs create -o mountpoint=/usr/src tank/funtoo/src
# zfs create -o mountpoint=/usr/portage -o compression=off tank/funtoo/portage
# zfs create -o mountpoint=/usr/portage/distfiles tank/funtoo/portage/distfiles
# zfs create -o mountpoint=/usr/portage/packages tank/funtoo/portage/packages
</pre>

## Installing Funtoo

### Pre-Chroot

<pre>Go into the directory that you will chroot into
# cd /mnt/funtoo

Make a boot folder and mount your boot drive
# mkdir boot
# mount /dev/sda1 boot
</pre>

[Now download and extract the Funtoo stage3 ...](http://www.funtoo.org/Funtoo_Linux_Installation "Funtoo Linux Installation")

Once you've extracted the stage3, do a few more preparations and chroot into your new funtoo environment:

<pre>Bind the kernel related directories
# mount -t proc none proc
# mount --rbind /dev dev
# mount --rbind /sys sys

Copy network settings
# cp -f /etc/resolv.conf etc

Make the zfs folder in 'etc' and copy your zpool.cache
# mkdir etc/zfs
# cp /tmp/zpool.cache etc/zfs

Chroot into Funtoo
# env -i HOME=/root TERM=$TERM chroot . bash -l
</pre>

### Downloading the Portage tree

<div>

<div>Note</div>

For an alternative way to do this, see [Installing Portage From Snapshot](http://www.funtoo.org/Installing_Portage_From_Snapshot "Installing Portage From Snapshot").

</div>

Now it's time to install a copy of the Portage repository, which contains package scripts (ebuilds) that tell portage how to build and install thousands of different software packages. To create the Portage repository, simply run `emerge --sync` from within the chroot. This will automatically clone the portage tree from [GitHub](https://github.com/funtoo/ports-2012):

<pre>(chroot) # emerge --sync
</pre>

<div>

<div>Important</div>

If you receive the error with initial `emerge --sync` due to git protocol restrictions, change `SYNC` variable in `/etc/portage/make.conf`:

<pre>SYNC="[https://github.com/funtoo/ports-2012.git](https://github.com/funtoo/ports-2012.git)"
</pre>

</div>

### Add filesystems to /etc/fstab

Before we continue to compile and or install our kernel in the next step, we will edit the `/etc/fstab` file because if we decide to install our kernel through portage, portage will need to know where our `/boot` is, so that it can place the files in there.

Edit `/etc/fstab`:

<div><tt>**/etc/fstab**</tt>

<pre># <fs>                  <mountpoint>    <type>          <opts>          <dump/pass>

/dev/sda1               /boot           ext2            defaults        0 2
</pre>

</div>

## Kernel Configuration

...wip

## Installing the ZFS userspace tools and kernel modules

Emerge sys-fs/zfs (package not on wiki - [please add](http://www.funtoo.org/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")). This package will bring in sys-kernel/spl (package not on wiki - [please add](http://www.funtoo.org/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")), and sys-fs/zfs-kmod (package not on wiki - [please add](http://www.funtoo.org/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")) as its dependencies:

<pre># emerge zfs
</pre>

Check to make sure that the zfs tools are working. The `zpool.cache` file that you copied before should be displayed.

<pre># zpool status
# zfs list
</pre>

If everything worked, continue.

## Create the initramfs

### genkernel

Install genkernel and run it:

<pre># emerge genkernel

You only need to add --luks if you used encryption
# genkernel --zfs --luks initramfs
</pre>

## Installing & Configuring the Bootloader

### GRUB 2

<pre># emerge grub
</pre>

Now install grub to the drive itself (not a partition):

<pre># grub-install /dev/sda
</pre>

### boot-update

boot-update comes as a dependency of grub2, so if you already installed grub, it's already on your system!

#### Genkernel

If your using genkernel you must add 'real_root=ZFS=<root>' and 'dozfs' to your params. Example entry for `/etc/boot.conf`:

<div><tt>**/etc/boot.conf**</tt>

<pre>"Funtoo ZFS" {
        kernel kernel[-v]
        initrd initramfs-genkernel-x86_64[-v]
        params real_root=ZFS=tank/funtoo/root
        params += dozfs=force
}
</pre>

</div>

After editing /etc/boot.conf, you just need to run boot-update to update grub.cfg

<pre># boot-update
</pre>

## Final configuration

### Add the zfs tools to openrc

<pre># rc-update add zfs boot</pre>

### Clean up and reboot

We are almost done, we are just going to clean up, **set our root password**, and unmount whatever we mounted and get out.

<pre>Delete the stage3 tarball that you downloaded earlier so it doesn't take up space.
# cd /
# rm stage3-latest.tar.xz

Set your root password
# passwd
>> Enter your password, you won't see what you are writing (for security reasons), but it is there!

Get out of the chroot environment
# exit

Unmount all the kernel filesystem stuff and boot (if you have a separate /boot)
# umount -l proc dev sys boot

Turn off the swap
# swapoff /dev/zvol/tank/swap

Export the zpool
# cd /
# zpool export tank

Reboot
# reboot
</pre>

<div>

<div>Important</div>

**Don't forget to set your root password as stated above before exiting chroot and rebooting. If you don't set the root password, you won't be able to log into your new system.**

</div>

and that should be enough to get your system to boot on ZFS.

## After reboot

### Forgot to reset password?

#### System Rescue CD

If you aren't using bliss-initramfs, then you can reboot back into your sysresccd and reset through there by mounting your drive, chrooting, and then typing passwd.

Example:

<pre># zpool import -f -R /mnt/funtoo tank
# chroot /mnt/funtoo bash -l
# passwd
# exit
# zpool export -f tank
# reboot
</pre>

### Create initial ZFS Snapshot

Continue to set up anything you need in terms of /etc configurations. Once you have everything the way you like it, take a snapshot of your system. You will be using this snapshot to revert back to this state if anything ever happens to your system down the road. The snapshots are cheap, and almost instant.

To take the snapshot of your system, type the following:

<pre># zfs snapshot -r tank@install</pre>

To see if your snapshot was taken, type:

<pre># zfs list -t snapshot</pre>

If your machine ever fails and you need to get back to this state, just type (This will only revert your / dataset while keeping the rest of your data intact):

<pre># zfs rollback tank/funtoo/root@install</pre>

<div>

<div>Important</div>

**For a detailed overview, presentation of ZFS' capabilities, as well as usage examples, please refer to the undefined page.**

</div>

## Troubleshooting

### Starting from scratch

If your installation has gotten screwed up for whatever reason and you need a fresh restart, you can do the following from sysresccd to start fresh:

<pre>Destroy the pool and any snapshots and datasets it has
# zpool destroy -R -f tank

This deletes the files from /dev/sda1 so that even after we zap, recreating the drive in the exact sector
position and size will not give us access to the old files in this partition.
# mkfs.ext2 /dev/sda1
# sgdisk -Z /dev/sda
</pre>

Now start the guide again :).

</div>

<div>

<div>[Categories](http://www.funtoo.org/Special:Categories "Special:Categories"): 

*   [HOWTO](http://www.funtoo.org/Category:HOWTO "Category:HOWTO")
*   [Filesystems](http://www.funtoo.org/Category:Filesystems "Category:Filesystems")
*   [Featured](http://www.funtoo.org/Category:Featured "Category:Featured")
*   [Install](http://www.funtoo.org/Category:Install "Category:Install")

</div>

</div>

</article>

</div>

<footer role="contentinfo">

<div>

<div>[undefined](http://www.mediawiki.org/)[undefined](https://www.semantic-mediawiki.org/wiki/Semantic_MediaWiki)</div>

*   This page was last modified on January 24, 2015, at 05:38.
*   [Privacy policy](http://www.funtoo.org/Funtoo:Privacy_policy "Funtoo:Privacy policy")
*   [About Funtoo](http://www.funtoo.org/Funtoo:About "Funtoo:About")
*   [Disclaimers](http://www.funtoo.org/Funtoo:General_disclaimer "Funtoo:General disclaimer")
