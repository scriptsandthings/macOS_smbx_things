#!/bin/bash
#
# Greg Knackstedt
# gmknacks(AT)gmail.com
# 1.26.2020 - 8:30pm
#
# DefaultsWriteCurrentUserJamf.sh
#
# For information on how to use defaults write refer to the man page
# man defaults
#
# Use the defaults write command to change a defined setting in a .plist for the current user
# Uses Jamf script parameters for portability
#
# By defining script parameters $4, $5, $6, and $7, the following example command
# would be executed targeting the currently logged in user
#
# $ defaults write com.apple.desktopservices.plist DSDontWriteNetworkStores true
#
################ Script Parameters ################
#
# $4 - Define path to directory containing .plist within the user directory
# Do not include an opening / or trailing / in the path
# Example: Preferences/Microsoft
#
# $5 - Define .plist file to target
# You use the full file name including the file extension
# Example: com.apple.desktopservices.plist
#
# $6 - Define the string to target with defaults write
# Example: DSDontWriteNetworkStores
#
# $7 - Define value to set for the string
# Example: true
#
################ Variables ################
#
# Identify currently logged in user
CurrentUser=`stat -f "%Su" /dev/console`
#
# Define the current user's home directory
UserHome=/Users/$CurrentUser
#
# Define current user's /Library/Preferences/ folder
UserLib=$UserHome/Library/
#
# Define path to directory containing .plist within the user directory
# Example: Preferences/Microsoft
PlistDir=$4
#
# Define .plist file to target
# Example: com.apple.desktopservices.plist
TargetPlist=$5
#
# Combine above to define the full path to the target plist for current console UserDefaultsWrite
UserPlist=$UserLib/$PlistDir/$TargetPlist
#
# Define string to target with defaults write
# Example: DSDontWriteNetworkStores
TargetString=$6
#
# Define value to set $TargetString
TargetStringValue=$7
#
################ Functions ################
#
# Call defaults write to apply the defined value to the defined string in the targeted .plist for current user
function UserDefaultsWrite
	{
		defaults write $UserPlist $TargetString $TargetStringValue
	}
#
# Set ownership of plist to $CurrentUser:staff
function RepairOwnership
	{
		chown -Rf $CurrentUser:staff $UserPlist
	}
#
# Restart services for CFPreferences and NSUserDefaults
function ApplyChange
	{
		killall cfprefsd
	}
#
################ Script ################
#
UserDefaultsWrite
RepairOwnership
ApplyChange
