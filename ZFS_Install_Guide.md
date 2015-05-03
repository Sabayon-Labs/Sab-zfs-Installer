notes usig this as guide to get this all blended up. 
<nav id="topnavbar" role="navigation" class="navbar navbar-inverse navbar-default">

<div class="container">

<div class="navbar-header"><button class="navbar-toggle" type="button" data-toggle="collapse" data-target="#navbarCollapse"><span class="sr-only">Toggle navigation</span> <span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button>[undefined](/Welcome)</div>

<div id="navbarCollapse" class="collapse navbar-collapse">

*   <a href="" data-toggle="dropdown" class="dropdown-toggle">Go</a>
    *   [Home](/Welcome)
    *   [Download](/Subarches)
    *   [Install](/Funtoo_Linux_Installation)
    *   [Ebuilds](/Ebuilds)
    *   [How to 'wiki'](/Help:Funtoo_Editing_Guidelines)
    *   [How to 'dev'](/How_to_Dev)
    *   [Kernels](/Funtoo_Linux_Kernels)
    *   [Dev Guide](/Developer_Guide)
    *   [Forums](http://forums.funtoo.org)
    *   [Usermap](/Usermap)

    *   [Articles](/Category:Articles)
    *   [HOWTOs](/Category:HOWTO)
    *   [Tutorials](/Category:Tutorial)
    *   [Networking](/Category:Networking)
    *   [Portage](/Category:Portage)
    *   [FLOPs](/Category:FLOP)

    *   [Recent changes](/Special:RecentChanges "A list of recent changes in the wiki [r]")
    *   [Help](https://www.mediawiki.org/wiki/Special:MyLanguage/Help:Contents "The place to find out")

*   <a href="" data-toggle="dropdown" class="dropdown-toggle"><span class="title">Actions</span></a>
    *   [View source](/index.php?title=ZFS_Install_Guide&action=edit "This page is protected.
        You can view its source [e]")
    *   [History](/index.php?title=ZFS_Install_Guide&action=history "Past revisions of this page [h]")

    *   [Page](/ZFS_Install_Guide "View the content page [c]")
    *   [Discussion](/Talk:ZFS_Install_Guide "Discussion about the content page [t]")

*   <a href="" data-toggle="dropdown" class="dropdown-toggle"><span class="title">Tools</span></a>
    *   [What links here](/Special:WhatLinksHere/ZFS_Install_Guide "A list of all wiki pages that link here [j]")
    *   [Related changes](/Special:RecentChangesLinked/ZFS_Install_Guide "Recent changes in pages linked from this page [k]")
    *   [Special pages](/Special:SpecialPages "A list of all special pages [q]")
    *   [Printable version](/index.php?title=ZFS_Install_Guide&printable=yes "Printable version of this page [p]")
    *   [Permanent link](/index.php?title=ZFS_Install_Guide&oldid=8747 "Permanent link to this revision of the page")
    *   [Page information](/index.php?title=ZFS_Install_Guide&action=info)
    *   [Browse properties](/Special:Browse/ZFS_Install_Guide)
*   [undefinedundefinedundefined](# "Personal tools")
    *   [Log in](/index.php?title=Special:UserLogin&returnto=ZFS+Install+Guide)

<form class="navbar-form navbar-right" role="search" method="get">

<div class="form-group" style="display:inline;">

<div class="input-group"><input type="search" class="form-control" name="search" placeholder="Search" id="searchInput">

<div class="input-group-btn"><button type="submit" class="btn btn-info" id="searchGoButton"><span class="glyphicon glyphicon-search"></span></button></div>

</div>

</div>

</form>

</div>

</div>

</nav>

<div id="page">

<div id="lower-container" class="">

<div class="bootstrap-ve"></div>

<div id="content-container" class="container has-title">

<article id="content" class="mw-body " role="main"><a id="top"></a>

# ZFS Install Guide

<div id="bodyContent">

<div id="mw-content-text" lang="en" dir="ltr" class="mw-content-ltr">

## <span class="mw-headline" id="Introduction">Introduction</span>

This tutorial will show you how to install Funtoo on ZFS (rootfs). This tutorial is meant to be an "overlay" over the [Regular Funtoo Installation](/Funtoo_Linux_Installation "Funtoo Linux Installation"). Follow the normal installation and only use this guide for steps 2, 3, and 8.

### <span class="mw-headline" id="Introduction_to_ZFS">Introduction to ZFS</span>

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

For a quick tour of ZFS and have a big picture of its common operations you can consult the page [ZFS Fun](/ZFS_Fun "ZFS Fun").

### <span class="mw-headline" id="Disclaimers">Disclaimers</span>

<div class="bs-callout bs-callout-danger">

<div class="bs-head">Warning</div>

This guide is a work in progress. Expect some quirks.

</div>

<div class="bs-callout bs-callout-warning">

<div class="bs-head">Important</div>

**Since ZFS was really designed for 64 bit systems, we are only recommending and supporting 64 bit platforms and installations. We will not be supporting 32 bit platforms**!

</div>

## <span class="mw-headline" id="Downloading_the_ISO_.28With_ZFS.29">Downloading the ISO (With ZFS)</span>

In order for us to install Funtoo on ZFS, you will need an environment that already provides the ZFS tools. Therefore we will download a customized version of System Rescue CD with ZFS included.

<pre>Name: sysresccd-4.2.0_zfs_0.6.2.iso  (545 MB)
Release Date: 2014-02-25
md5sum 01f4e6929247d54db77ab7be4d156d85
</pre>

**undefined**

## <span class="mw-headline" id="Creating_a_bootable_USB_from_ISO_.28From_a_Linux_Environment.29">Creating a bootable USB from ISO (From a Linux Environment)</span>

After you download the iso, you can do the following steps to create a bootable USB:

<pre class="code">Make a temporary directory
# <span class="code_input">mkdir /tmp/loop</span>

Mount the iso
# <span class="code_input">mount -o ro,loop /root/sysresccd-4.2.0_zfs_0.6.2.iso /tmp/loop</span>

Run the usb installer
# <span class="code_input">/tmp/loop/usb_inst.sh</span>
</pre>

That should be all you need to do to get your flash drive working.

## <span class="mw-headline" id="Booting_the_ISO">Booting the ISO</span>

<div class="bs-callout bs-callout-danger">

<div class="bs-head">Warning</div>

**When booting into the ISO, Make sure that you select the "Alternate 64 bit kernel (altker64)". The ZFS modules have been built specifically for this kernel rather than the standard kernel. If you select a different kernel, you will get a fail to load module stack error message.**

</div>

## <span class="mw-headline" id="Creating_partitions">Creating partitions</span>

There are two ways to partition your disk: You can use your entire drive and let ZFS automatically partition it for you, or you can do it manually.

We will be showing you how to partition it **manually** because if you partition it manually you get to create your own layout, you get to have your own separate /boot partition (Which is nice since not every bootloader supports booting from ZFS pools), and you get to boot into RAID10, RAID5 (RAIDZ) pools and any other layouts due to you having a separate /boot partition.

#### <span class="mw-headline" id="gdisk_.28GPT_Style.29">gdisk (GPT Style)</span>

**A Fresh Start**:

First lets make sure that the disk is completely wiped from any previous disk labels and partitions. We will also assume that <tt>/dev/sda</tt> is the target drive.

<pre class="code"># <span class="code_input">sgdisk -Z /dev/sda</span>
</pre>

<div class="bs-callout bs-callout-danger">

<div class="bs-head">Warning</div>

This is a destructive operation and the program will not ask you for confirmation! Make sure you really don't want anything on this disk.

</div>

Now that we have a clean drive, we will create the new layout.

First open up the application:

<pre class="code"># <span class="code_input">gdisk /dev/sda</span>
</pre>

**Create Partition 1** (boot):

<pre class="code">Command: <span class="code_input">n ↵</span>
Partition Number: <span class="code_input">↵</span>
First sector: <span class="code_input">↵</span>
Last sector: <span class="code_input">+250M ↵</span>
Hex Code: <span class="code_input">↵</span>
</pre>

**Create Partition 2** (BIOS Boot Partition):

<pre class="code">Command: <span class="code_input">n ↵</span>
Partition Number: <span class="code_input">↵</span>
First sector: <span class="code_input">↵</span>
Last sector: <span class="code_input">+32M ↵</span>
Hex Code: <span class="code_input">EF02 ↵</span>
</pre>

**Create Partition 3** (ZFS):

<pre class="code">Command: <span class="code_input">n ↵</span>
Partition Number: <span class="code_input">↵</span>
First sector: <span class="code_input">↵</span>
Last sector: <span class="code_input">↵</span>
Hex Code: <span class="code_input">bf00 ↵</span>

Command: <span class="code_input">p ↵</span>

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048          514047   250.0 MiB   8300  Linux filesystem
   2          514048          579583   32.0 MiB    EF02  BIOS boot partition
   3          579584      1953525134   931.2 GiB   BF00  Solaris root

Command: <span class="code_input">w ↵</span>
</pre>

### <span class="mw-headline" id="Format_your_.2Fboot_partition">Format your /boot partition</span>

<pre class="code"># <span class="code_input">mkfs.ext2 -m 1 /dev/sda1</span>
</pre>

### <span class="mw-headline" id="Create_the_zpool">Create the zpool</span>

We will first create the pool. The pool will be named `tank`. Feel free to name your pool as you want. We will use `ashift=12` option which is used for a hard drives with a 4096 sector size.

<pre class="code"># <span class="code_input">  zpool create -f -o ashift=12 -o cachefile=/tmp/zpool.cache -O normalization=formD -m none -R /mnt/funtoo tank /dev/sda3 </span></pre>

### <span class="mw-headline" id="Create_the_zfs_datasets">Create the zfs datasets</span>

We will now create some datasets. For this installation, we will create a small but future proof amount of datasets. We will have a dataset for the OS (/), and your swap. We will also show you how to create some optional datasets as examples ones: `/home`, `/usr/src`, and `/usr/portage`.

<pre class="code">Create some empty containers for organization purposes, and make the dataset that will hold /
# <span class="code_input">zfs create -p tank/funtoo</span>
# <span class="code_input">zfs create -o mountpoint=/ tank/funtoo/root</span>

Optional, but recommended datasets: /home
# <span class="code_input">zfs create -o mountpoint=/home tank/funtoo/home</span>

Optional datasets: /usr/src, /usr/portage/{distfiles,packages}
# <span class="code_input">zfs create -o mountpoint=/usr/src tank/funtoo/src</span>
# <span class="code_input">zfs create -o mountpoint=/usr/portage -o compression=off tank/funtoo/portage</span>
# <span class="code_input">zfs create -o mountpoint=/usr/portage/distfiles tank/funtoo/portage/distfiles</span>
# <span class="code_input">zfs create -o mountpoint=/usr/portage/packages tank/funtoo/portage/packages</span>
</pre>

## <span class="mw-headline" id="Installing_Funtoo">Installing Funtoo</span>

### <span class="mw-headline" id="Pre-Chroot">Pre-Chroot</span>

<pre class="code">Go into the directory that you will chroot into
# <span class="code_input">cd /mnt/funtoo</span>

Make a boot folder and mount your boot drive
# <span class="code_input">mkdir boot</span>
# <span class="code_input">mount /dev/sda1 boot</span>
</pre>

[Now download and extract the Funtoo stage3 ...](/Funtoo_Linux_Installation "Funtoo Linux Installation")

Once you've extracted the stage3, do a few more preparations and chroot into your new funtoo environment:

<pre class="code">Bind the kernel related directories
# <span class="code_input">mount -t proc none proc</span>
# <span class="code_input">mount --rbind /dev dev</span>
# <span class="code_input">mount --rbind /sys sys</span>

Copy network settings
# <span class="code_input">cp -f /etc/resolv.conf etc</span>

Make the zfs folder in 'etc' and copy your zpool.cache
# <span class="code_input">mkdir etc/zfs</span>
# <span class="code_input">cp /tmp/zpool.cache etc/zfs</span>

Chroot into Funtoo
# <span class="code_input">env -i HOME=/root TERM=$TERM chroot . bash -l</span>
</pre>

### <span class="mw-headline" id="Downloading_the_Portage_tree">Downloading the Portage tree</span>

<div class="bs-callout bs-callout-info">

<div class="bs-head">Note</div>

For an alternative way to do this, see [Installing Portage From Snapshot](/Installing_Portage_From_Snapshot "Installing Portage From Snapshot").

</div>

Now it's time to install a copy of the Portage repository, which contains package scripts (ebuilds) that tell portage how to build and install thousands of different software packages. To create the Portage repository, simply run `emerge --sync` from within the chroot. This will automatically clone the portage tree from [GitHub](https://github.com/funtoo/ports-2012):

<pre class="code">(chroot) # <span class="code_input">emerge --sync</span>
</pre>

<div class="bs-callout bs-callout-warning">

<div class="bs-head">Important</div>

If you receive the error with initial `emerge --sync` due to git protocol restrictions, change `SYNC` variable in `/etc/portage/make.conf`:

<pre>SYNC="https://github.com/funtoo/ports-2012.git"
</pre>

</div>

### <span class="mw-headline" id="Add_filesystems_to_.2Fetc.2Ffstab">Add filesystems to /etc/fstab</span>

Before we continue to compile and or install our kernel in the next step, we will edit the `/etc/fstab` file because if we decide to install our kernel through portage, portage will need to know where our `/boot` is, so that it can place the files in there.

Edit `/etc/fstab`:

<div style="margin-bottom: 0.3em; padding: 3px; border: none;"><tt>**/etc/fstab**</tt><span style="color: #888;"></span>

<pre lang="{{{lang}}}"># <fs>                  <mountpoint>    <type>          <opts>          <dump/pass>

/dev/sda1               /boot           ext2            defaults        0 2
</pre>

</div>

## <span class="mw-headline" id="Kernel_Configuration">Kernel Configuration</span>

...wip

## <span class="mw-headline" id="Installing_the_ZFS_userspace_tools_and_kernel_modules">Installing the ZFS userspace tools and kernel modules</span>

Emerge sys-fs/zfs (package not on wiki - [please add](/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")). This package will bring in sys-kernel/spl (package not on wiki - [please add](/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")), and sys-fs/zfs-kmod (package not on wiki - [please add](/Adding_an_Ebuild_to_the_Wiki "Adding an Ebuild to the Wiki")) as its dependencies:

<pre class="code"># <span class="code_input">emerge zfs</span>
</pre>

Check to make sure that the zfs tools are working. The `zpool.cache` file that you copied before should be displayed.

<pre class="code"># <span class="code_input">zpool status</span>
# <span class="code_input">zfs list</span>
</pre>

If everything worked, continue.

## <span class="mw-headline" id="Create_the_initramfs">Create the initramfs</span>

### <span class="mw-headline" id="genkernel">genkernel</span>

Install genkernel and run it:

<pre class="code"># <span class="code_input">emerge genkernel</span>

You only need to add --luks if you used encryption
# <span class="code_input">genkernel --zfs --luks initramfs</span>
</pre>

## <span class="mw-headline" id="Installing_.26_Configuring_the_Bootloader">Installing & Configuring the Bootloader</span>

### <span class="mw-headline" id="GRUB_2">GRUB 2</span>

<pre class="code"># <span class="code_input">emerge grub</span>
</pre>

Now install grub to the drive itself (not a partition):

<pre class="code"># <span class="code_input">grub-install /dev/sda</span>
</pre>

### <span class="mw-headline" id="boot-update">boot-update</span>

boot-update comes as a dependency of grub2, so if you already installed grub, it's already on your system!

#### <span class="mw-headline" id="Genkernel_2">Genkernel</span>

If your using genkernel you must add 'real_root=ZFS=<root>' and 'dozfs' to your params. Example entry for `/etc/boot.conf`:

<div style="margin-bottom: 0.3em; padding: 3px; border: none;"><tt>**/etc/boot.conf**</tt><span style="color: #888;"></span>

<pre lang="{{{lang}}}">"Funtoo ZFS" {
        kernel kernel[-v]
        initrd initramfs-genkernel-x86_64[-v]
        params real_root=ZFS=tank/funtoo/root
        params += dozfs=force
}
</pre>

</div>

After editing /etc/boot.conf, you just need to run boot-update to update grub.cfg

<pre class="code">#<span class="code_input"> boot-update</span>
</pre>

## <span class="mw-headline" id="Final_configuration">Final configuration</span>

### <span class="mw-headline" id="Add_the_zfs_tools_to_openrc">Add the zfs tools to openrc</span>

<pre class="code"># <span class="code_input">rc-update add zfs boot</span></pre>

### <span class="mw-headline" id="Clean_up_and_reboot">Clean up and reboot</span>

We are almost done, we are just going to clean up, **set our root password**, and unmount whatever we mounted and get out.

<pre class="code">Delete the stage3 tarball that you downloaded earlier so it doesn't take up space.
# <span class="code_input">cd /</span>
# <span class="code_input">rm stage3-latest.tar.xz</span>

Set your root password
# <span class="code_input">passwd</span>
>> Enter your password, you won't see what you are writing (for security reasons), but it is there!

Get out of the chroot environment
# <span class="code_input">exit</span>

Unmount all the kernel filesystem stuff and boot (if you have a separate /boot)
# <span class="code_input">umount -l proc dev sys boot</span>

Turn off the swap
# <span class="code_input">swapoff /dev/zvol/tank/swap</span>

Export the zpool
# <span class="code_input">cd /</span>
# <span class="code_input">zpool export tank</span>

Reboot
# <span class="code_input">reboot</span>
</pre>

<div class="bs-callout bs-callout-warning">

<div class="bs-head">Important</div>

**Don't forget to set your root password as stated above before exiting chroot and rebooting. If you don't set the root password, you won't be able to log into your new system.**

</div>

and that should be enough to get your system to boot on ZFS.

## <span class="mw-headline" id="After_reboot">After reboot</span>

### <span class="mw-headline" id="Forgot_to_reset_password.3F">Forgot to reset password?</span>

#### <span class="mw-headline" id="System_Rescue_CD">System Rescue CD</span>

If you aren't using bliss-initramfs, then you can reboot back into your sysresccd and reset through there by mounting your drive, chrooting, and then typing passwd.

Example:

<pre class="code"># <span class="code_input">zpool import -f -R /mnt/funtoo tank</span>
# <span class="code_input">chroot /mnt/funtoo bash -l</span>
# <span class="code_input">passwd</span>
# <span class="code_input">exit</span>
# <span class="code_input">zpool export -f tank</span>
# <span class="code_input">reboot</span>
</pre>

### <span class="mw-headline" id="Create_initial_ZFS_Snapshot">Create initial ZFS Snapshot</span>

Continue to set up anything you need in terms of /etc configurations. Once you have everything the way you like it, take a snapshot of your system. You will be using this snapshot to revert back to this state if anything ever happens to your system down the road. The snapshots are cheap, and almost instant.

To take the snapshot of your system, type the following:

<pre class="code"># <span class="code_input">zfs snapshot -r tank@install</span></pre>

To see if your snapshot was taken, type:

<pre class="code"># <span class="code_input">zfs list -t snapshot</span></pre>

If your machine ever fails and you need to get back to this state, just type (This will only revert your / dataset while keeping the rest of your data intact):

<pre class="code"># <span class="code_input">zfs rollback tank/funtoo/root@install</span></pre>

<div class="bs-callout bs-callout-warning">

<div class="bs-head">Important</div>

**For a detailed overview, presentation of ZFS' capabilities, as well as usage examples, please refer to the undefined page.**

</div>

## <span class="mw-headline" id="Troubleshooting">Troubleshooting</span>

### <span class="mw-headline" id="Starting_from_scratch">Starting from scratch</span>

If your installation has gotten screwed up for whatever reason and you need a fresh restart, you can do the following from sysresccd to start fresh:

<pre class="code">Destroy the pool and any snapshots and datasets it has
# <span class="code_input">zpool destroy -R -f tank</span>

This deletes the files from /dev/sda1 so that even after we zap, recreating the drive in the exact sector
position and size will not give us access to the old files in this partition.
# <span class="code_input">mkfs.ext2 /dev/sda1</span>
# <span class="code_input">sgdisk -Z /dev/sda</span>
</pre>

Now start the guide again :).

</div>

<div class="printfooter">Retrieved from "[http://www.funtoo.org/index.php?title=ZFS_Install_Guide&oldid=8747](http://www.funtoo.org/index.php?title=ZFS_Install_Guide&oldid=8747)"</div>

<div id="catlinks" class="catlinks">

<div id="mw-normal-catlinks" class="mw-normal-catlinks">[Categories](/Special:Categories "Special:Categories"):

*   [HOWTO](/Category:HOWTO "Category:HOWTO")
*   [Filesystems](/Category:Filesystems "Category:Filesystems")
*   [Featured](/Category:Featured "Category:Featured")
*   [Install](/Category:Install "Category:Install")

</div>

</div>

</div>

</article>

</div>

</div>

<footer id="main-footer" role="contentinfo">

<div class="container">

<div id="f-poweredbyico">[undefined](//www.mediawiki.org/)[undefined](https://www.semantic-mediawiki.org/wiki/Semantic_MediaWiki)</div>

*   This page was last modified on January 24, 2015, at 05:38.
*   [Privacy policy](/Funtoo:Privacy_policy "Funtoo:Privacy policy")
*   [About Funtoo](/Funtoo:About "Funtoo:About")
*   [Disclaimers](/Funtoo:General_disclaimer "Funtoo:General disclaimer")

</div>

</footer>
