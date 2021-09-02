#!/bin/bash
#########################################
# DisplaySMBStatus.sh                   #
# Displays current smb mountpoint stats #
#########################################
# Greg Knackstedt                       #
# 9.1.2021                              #
# ShitttyScripts@gmail.com              #
#########################################
#
# Set smbutil command
ShowSMBStatus=$(smbutil statshares -a)
#
# Set Timestamp
Timestamp=$(date)
#
# Begin Apple Script
/usr/bin/osascript << EOF

tell application "Finder"

activate

display dialog "SMB share status for $USER at $Timestamp" & return & return & "NOTE: If formatting is difficult to read, copy/paste results into a text editor." & return & return & "$ShowSMBStatus" buttons {"================================================= Dismiss ================================================="} with icon caution

end tell

EOF


exit 0
