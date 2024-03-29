


# Apple macOS smbx and /etc/nsmb.conf information

Greg Knackstedt

Created: 1.2020

Last Update: 4.2022

##### Things that might make smbx suck a little less and some scripts to help deploy them.


This is a compilation of data from Apple, multiple storage vendors, and the internet at large, of various issues and workarounds to make Apple's smbx implementation play a little nicer.

Each one of the items in this document can be deployed with one of the scripts in the [in the Scripts directory](https://github.com/scriptsandthings/macOS_smbx_things/tree/master/Scripts) of this reposatory.

# Always test before using, never test in prod, use these at your own risk.

# Disable file and icon previews in Finder

https://www.jamf.com/jamf-nation/discussions/24619/disabling-icon-preview

I hate to throw a [google search link here](https://www.google.com/search?q=mac+smb+preview+file+lock&oq=mac+smb+preview+file+lock&aqs=chrome..69i57j69i64.7547j0j7&sourceid=chrome&ie=UTF-8) but, this seems to still be a thing (adjust with Tools for recent results).


### Having previews enabled for files and icons in different Finder view settings can result in file lock/permissions errors for all other users on the same share. This is a result of the interaction between the way macOS generates the preview and the status that sets on the file.

Set the cover-flow preview setting to off

Set the icon preview setting to off

Set the list icon preview setting to off

Set the column icon preview setting to off

Set the column preview column setting to off

# Disable SMB packet signing - macOS 10.13.3 and earlier

https://support.apple.com/en-us/HT205926

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 12 as of 4.22

### In macOS 10.13.4 and later, packet signing is off by default. Packet signing for SMB 2 or SMB 3 connections turns on automatically when needed if the server offers it. The instructions in this article apply to macOS 10.13.3 and earlier. When using an SMB 2 or SMB 3 connection, packet signing is turned on by default.

##### However, the extra overhead of packet signing can cause significant performance degradation on the latency-sensitive,
high-performance workloads common to network shares used in design heavy workflows.

You might want to turn off packet signing if:
- Performance decreases when you connect to a third party server.
- You can’t connect to a server that doesn’t support packet signing.
- You can’t connect a third party device to your macOS SMB server.

Given the inconsistent nature of the SMB signing behavior in macOS it is recommended to manually disable
the feature using the /etc/nsmb.conf file.

Apple outlines disabling SMB signing in the archived support article [Turn off packet signing for SMB 2 and SMB 3
connections](https://support.apple.com/en-us/HT205926).

To disable SMB signing on macOS, add the following entry to /etc/nsmb.conf:

signing_required=no

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.

# Disable SMB session signing - macOS 10.13+ and SMB3

https://support.apple.com/en-us/HT205926

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 13 as of 4.22

### SMB3 introduces security enhancements that help prevent man in the middle attacks during the initiation of an SMB client connection to an SMB server. This is different from SMB signing which adds a digital signature to each packet. SMB session signing can be described as a way to protect an SMB session from being tampering with as it commences. In certain scenarios, particularly where macOS client systems are bound anonymously to a directory server, this may cause authentication errors when a system tries to connect to an SMB share.

In situations where proper network credentials are not working from macOS systems running version 10.13+, disabling SMB session signing may resolve the issue. Similar to disabling SMB signing, this reduces the security of an SMB connection and is recommended on systems running on private, secure networks.

Add the following line to the /etc/nsmb.conf file:

validate_neg_off=yes

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.

# Prevent macOS from reading .DS_Store files on network shares - Disable directory caching - macOS 10.13+

https://support.apple.com/en-us/HT208209

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 11 as of 4.22

### Speeds up SMB file browsing by preventing macOS from reading .DS_Store files on SMB shares. This makes the Finder use only basic information to immediately display each folder's contents in alphanumeric order.

The macOS Finder automatically creates .DS_Store files in every folder it accesses. This file stores
metadata about how to display that directory’s contents. The reading and writing of these files can slow down
performance when listing the contents of directories with high file counts.
It is possible to prevent macOS from creating .DS_Store files on network shares in macOS 10.13. As of
macOS 10.14, it is no longer possible to stop these files from being created on network shares. However, it is
possible to prevent macOS from reading the .DS_Store file before listing a directory’s contents. In the
absence of a .DS_Store file or if reading the .DS_Store file is suppressed (as in 10.14 and higher),
macOS will list the contents of a folder in alphanumeric order only upon initial open. Listing folders in this way
has been shown to significantly reduce the time it takes for macOS to display the contents of directories with
large numbers of files, such as those containing image sequences.

The following macOS CLI command prevents macOS 10.14 and higher from reading .DS_Store files on network shares:

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

Note: This same command works on macOS 10.13 and earlier, it just actually disables the .DS_Store file creation.

After running this command, the user will need to log out and log in for the changes to take effect.

For more information about .DS_Store files, see the [.DS_Store Wikipedia article.](https://en.wikipedia.org/wiki/.DS_Store) 

# TCP delayed acknowledgement (delayed_ack)

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 9 as of 4.22

http://www.stuartcheshire.org/papers/NagleDelayedAck/ (No SSL cert, site is an interesting read.)

### There are many explanations for TCP delayed acknowledgement (delayed_ack), such as the description in the article TCP Performance problems caused by interaction between Nagle’s Algorithm and Delayed ACK. For most uses of TCP, delayed acknowledgement is a good thing and makes network communication more efficient. TCP acknowledgements are added to subsequent data packets. However, in practice on macOS, particularly with network connections lower than 1 GbE, TCP delayed There are four options in macOS for setting the characteristics of acknowledgement can cause performance degradation.

There are four options in macOS for setting the characteristics of delayed_ack:

- delayed_ack=0: Responds after every packet (OFF)
- delayed_ack=1: Always employs delayed_ack; 6 packets can get 1 ack- 
- delayed_ack=2: Immediate ack after 2nd packet; 2 packets per ack (Compatibility Mode)
- delayed_ack=3: Should auto detect when to employ delayed ack; 3 packets per ack

The default setting for macOS 10.14 and 10.15 is delayed_ack=3. 

Testing has shown that in some environments, particularly where the client is reading and writing simultaneously, delayed_ack=0 is typically
the ideal value. Rendering a video sequence is an example of such behavior.

In macOS 11, the default value is delayed_ack=0.

While it is possible to temporarily change this value with the below sysctl -w command, the change does not persist across reboots. Values set for delayed_ack in the sysctl.conf file are ignored in macOS 11. Thus it would appear that Apple has settled on delayed_ack=0 as being the ideal value.

However, testing has shown that in some environments — particularly where the client is reading and writing simultaneously (such as what happens when an application is rendering a video sequence) — changing the setting to delayed_ack=0 significantly improves performance.

It should be noted that environments vary, and that the settings should be tested in each environment. 

Sometimes, a setting of delayed_ack=1 or delayed_ack=2 will work best. 

It is important to also understand the impact of the change on other parts of the system.

To query the current setting of the client, enter the following at the macOS command line:

$ sudo sysctl net.inet.tcp.delayed_ack

Example response:

net.inet.tcp.delayed_ack: 3

To change this setting, enter the following at the macOS command line:

$ sudo sysctl -w net.inet.tcp.delayed_ack=0

Example response:

net.inet.tcp.delayed_ack: 3 -> 0

To make the setting persist over a reboot (in macOS 10.14 and 10.15), edit the /etc/sysctl.conf file on the macOS client:

Add the following line to the file at /etc/sysctl.conf:

net.inet.tcp.delayed_ack=0

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.

# Configure SMB Multichannel behavior - macOS 11.3+

https://support.apple.com/en-us/HT212277

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 7 as of 4.22

### SMB Multichannel allows macOS to establish more than one connection to an SMB server, increase transfer speeds, and provide redundancy. The server must support SMB Multichannel to use any of these features.

To enable redundancy, you should enable more than one network connection that allows connectivity to the SMB server. When SMB Multichannel is enabled, and more than one network is available, macOS prefers the network that advertises itself to be the fastest. For macOS to use multiple connections simultaneously for faster transfer rates, the interfaces must have the same speeds enabled.

If you want to fully disable SMB Multichannel support in macOS, add the following line to the /etc/nsmb.conf file:

mc_on=no

Some Wi-Fi networks advertise faster speeds than the connected wired network. If you want to leave SMB Multichannel enabled and use Wi-Fi only as a failover for redundancy, because you prefer wired connections, add the following line to the /etc/nsmb.conf file:

mc_prefer_wired=yes

The /etc/nsmb.conf file doesn't exist by default. To create one and apply both of the above changes, use the following Terminal commands:

echo "[default]" | sudo tee -a /etc/nsmb.conf
echo "mc_on=no" | sudo tee -a /etc/nsmb.conf
echo "mc_prefer_wired=yes" | sudo tee -a /etc/nsmb.conf

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.

For more information about the SMB Multichannel options supported on the active network, run the following Terminal command:
smbutil multichannel

# SMB change notifications

#### NOT suggested

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 13 as of 4.22

The SMB server provides macOS with updates or changes to mounted file shares. 

With a busy file share, this may result in the macOS Finder refreshing itself frequently and users may notice their file listings fluctuating or Finder windows reset to the top level directory while browsing. 

To avoid this behavior, it is possible to disable the Finder from requesting SMB change notifications.

Applying this setting can break workflows that require SMB notifications for folder listings to be current. For example, the collaborative Productions feature in Adobe™ Premiere Pro™ relies on change notifications to be active on all clients participating in the Production. Disabling change notifications can also lead to data corruption and other issues where multiple users are accessing the same files and directories.

Therefore, as with all macOS optimizations, great care and testing is required to make sure that enabling this setting does not cause workflow problems.

To disable SMB notification, add the following line to the /etc/nsmb.conf file:

notify_off=yes

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.

# Force SMB protocol version

https://www.dellemc.com/resources/en-us/asset/white-papers/products/storage/h17613_wp_isilon_mac_os_performance_optimization.pdf - Page 14 as of 4.22

Under certain circumstances, it may be desirable to force macOS to connect through a particular version of
SMB. 

Note: macOS uses a binary bitmap to specify which version of SMB to use. 

Add protocol_vers_map= and the appropriate value to force protocol types. See the following examples.

Protocol version is specified using binary bitmap

1 => 0001 => SMB 1 only

2 => 0010 => SMB 2 only

3 => 0011 => SMB 1 or 2

4 => 0100 => SMB 3 only

6 => 0110 => SMB 2 or 3

To Force SMB 3 only:

protocol_vers_map=4

To Force SMB 2 or 3 only

protocol_vers_map=6

After updating /etc/nsmb.conf, unmount and remount SMB shares from the macOS system for the changes to take effect.

To revert the above changes, you can delete the /etc/nsmb.conf file safely.
