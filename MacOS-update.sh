#!/bin/bash
# Applies hardening measures based on DISA Apple OS 10.11 STIG version 1 release 1
# http://iase.disa.mil/stigs/os/mac/Pages/index.asp (DoD PKI required)
# Installs system updates, reboots and repeats if necessary.
#
# STIG checks
# Check for FIPS 140 compliant Apple OSX CoreCrypto Module (Intel i5, Xeon, Core M processors)
sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate | grep LastSuccessfulDate | sed -e 's@^.* "\([0-9\\-]*\) .*$@\1@'); if [ "$LASTUPDATE" = "$(date +%Y-%m-%d)" ];then exit 0; fi; exit 1
sudo /usr/bin/softwareupdate -i -a

# Enable auto update
sudo /usr/bin/softwareupdate --schedule | grep 'Automatic check is on'
sudo /usr/bin/softwareupdate --schedule on

# Disable Bluetooth 
defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState | grep 0
sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0; sudo killall -HUP blued

# Check for FIPS 140 daemon
/System/Library/LaunchDaemons/com.apple.fipspost.plist
/usr/libexec/cc_fips_test
/usr/sbin/fips

# Disable infrared receiver (iTunes remote)
defaults read /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled | grep 0
sudo defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -int 0

# Disable AirDrop
sudo defaults read com.apple.NetworkBrowser DisableAirDrop | grep 1
defaults write com.apple.NetworkBrowser DisableAirDrop -bool YES

# Set time and date automatically
sudo systemsetup getusingnetworktime | grep 'Network Time: Off'
sudo systemsetup setusingnetworktime off

# Set an inactivity interval of 10 minutes (600 seconds) or less for the screen saver
UID=`ioreg -rd1 -c IOPlatformExpertDevice | grep "IOPlatformUUID" | sed -e 's/^.*"\(.*\)"$/\1/'`; for i in $(find /Users -type d -maxdepth 1); do PREF=$i/Library/Preferences/ByHost/com.apple.screensaver.$UUID; if [ -e $PREF.plist ]; then TIMEOUT=$(defaults read $PREF.plist idleTime) && if [ $TIMEOUT -eq 0 ] || [ $TIMEOUT -gt 600 ]; then exit 1; fi; fi; done; exit 0
UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep "IOPlatformUUID" | sed -e 's/^.*"\(.*\)"$/\1/'`; for i in $(find /Users -type d -maxdepth 1); do PREF=$i/Library/Preferences/ByHost/com.apple.screensaver.$UUID; if [ -e $PREF.plist ]; then defaults -currentHost write $PREF.plist idleTime -int 600; fi; done

# Enable secure screen saver corners
for i in $(find /Users -type d -maxdepth 1); do PREF=$i/Library/Preferences/com.apple.dock.plist; if [ -e $PREF ]; then CORNER=$(defaults read $PREF | grep corner | grep 6) && if [ -n "$CORNER" ]; then exit 1; fi; fi; done; exit 0
for i in $(find /Users -type d -maxdepth 1); do PREF=$i/Library/Preferences/com.apple.dock.plist; if [ -e $PREF ]; then CORNER=$(defaults read $PREF | grep corner | grep 6) && if [ -n "$CORNER" ]; then defaults write $PREF wvous-tr-corner 5; fi; fi; done;

# Require a password to wake the computer from sleep or screen saver
defaults read com.apple.screensaver askForPassword | grep 1
defaults write com.apple.screensaver askForPassword -int 1

# Ensure screen locks immediately when requested
defaults read com.apple.screensaver askForPasswordDelay | grep "0"
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Disable Remote Login 
sudo systemsetup -getremoteappleevents | grep "Remote Apple Events: Off"
sudo systemsetup -setremoteappleevents off

# Disable Internet Sharing
if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat ]; then NAT=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.nat | grep -i "Enabled = 0") && if [ -n "$NAT" ]; then exit 1; fi; fi; exit 0
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add Enabled -int 0

# Disable Screen Sharing
if [ -e /System/Library/LaunchDaemons/com.apple.screensharing.plist ]; then STATUS=$(launchctl load /System/Library/LaunchDaemons/com.apple.screensharing.plist | grep -v "Service is disabled") && if [ -n "$STATUS" ]; then exit 1; fi; fi; exit 0
launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

# Disable Printer Sharing
if [ -n "$(system_profiler SPPrintersDataType | grep Shared | grep Yes)" ]; then exit 1; fi; exit 0
cupsctl --no-share-printers

# Disable Wake on Network Access
sudo systemsetup getwakeonnetworkaccess | grep "Wake On Network Access: Off"
sudo systemsetup -setwakeonnetworkaccess off

# Disable File Sharing
if [ -n "$(launchctl list | egrep AppleFileServer)" ]; then exit 1; fi; if [ -n "$(grep -i array /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist)" ]; then exit 1; fi; exit 0;
launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist; launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist

# Disable Remote Management
if [ -n "$(ps -ef | egrep "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/[A]RDAgent")" ]; then exit 1; fi; exit 0
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop

# Enable FileVault
diskutil cs list | grep -i "Encryption Status: Unlocked"

# Destroy File Vault Key when going to standby 
pmset -g | grep DestroyFVKeyOnStandby | grep 1
sudo pmset -a destroyfvkeyonstandby 1

# Enable hibernation mode (no memory power on sleep)
pmset -g | grep hibernatemode | grep 25
sudo pmset -a hibernatemode 25

# Enable Gatekeeper
sudo softwareupdate --schedule | grep 'Automatic check is on'
sudo softwareupdate --schedule on

# Enable Firewall
spctl --status | grep "assessments enabled"
sudo spctl --master-enable

# Enable Firewall Stealth Mode
test $(defaults read /Library/Preferences/com.apple.alf globalstate) -ge 1
defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# Disable signed apps from being auto-permitted to listen through firewall
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep "Stealth mode enabled"
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Disable iCloud drive
if [ -n "$(defaults read NSGlobalDomain NSDocumentSaveNewDocumentsToCloud | grep "0")" ]; then exit 0; fi; exit 1;
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool falsee

# Require an administrator password to access system-wide preferences
if [ -n "$(security authorizationdb read system.preferences 2> /dev/null | grep -A1 shared | grep -E '(true|false)' | grep 'false')" ]; then exit 0; fi; exit 1
security authorizationdb read system.preferences > /tmp/system.preferences.plist &&/usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist && security authorizationdb write system.preferences < /tmp/system.preferences.plist

# Disable IPv6
networksetup -listallnetworkservices | while read i; do SUPPORT=$(networksetup -getinfo "$i" | grep "IPv6: Automatic") && if [ -n "$SUPPORT" ]; then exit 1; fi; done; exit 0
networksetup -listallnetworkservices | while read i; do SUPPORT=$(networksetup -getinfo "$i" | grep "IPv6: Automatic") && if [ -n "$SUPPORT" ]; then networksetup -setv6off "$i"; fi; done;

# Disable Previews
defaults read /Library/Preferences/com.apple.finder.plist | grep ShowIconThumbnails | grep 0
/usr/libexec/PlistBuddy -c "Add StandardViewOptions:ColumnViewOptions:ShowIconThumbnails bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:ListViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:IconViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:ExtendedListViewSettings:showIconPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewOptions:ColumnViewOptions:ShowPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:ListViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:IconViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist" && /usr/libexec/PlistBuddy -c "Add StandardViewSettings:ExtendedListViewSettings:showPreview bool NO" "/Library/Preferences/com.apple.finder.plist"

# Secure Safari by crippling it (use Chrome or Firefox)
defaults read com.apple.Safari WebKitOmitPDFSupport | grep 1
defaults write com.apple.Safari WebKitOmitPDFSupport -bool YES && defaults write com.apple.Safari WebKitJavaScriptEnabled -bool FALSE && defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptEnabled -bool FALSE

# Disable automatic loading of remote content by Mail.app
defaults read com.apple.mail-shared DisableURLLoading | grep 1
defaults write com.apple.mail-shared DisableURLLoading -bool true

# Disable Captive Portal 
defaults read /Library/Preferences/SystemConfiguration/com.apple.captive.control.plist | grep "Active = 0"
defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

# Enable logging
defaults read /Library/Preferences/com.apple.alf loggingenabled | grep 1
sudo defaults write /Library/Preferences/com.apple.alf loggingenabled -bool true

# Systems updates
SWUL=`/usr/sbin/softwareupdate -l | /usr/bin/awk '{printf "%s", $0}'`
SWULER=`/usr/sbin/softwareupdate -l 2>&1 | /usr/bin/head -1`
NoRestartUpdates=`/usr/sbin/softwareupdate -l | /usr/bin/grep -v restart | /usr/bin/grep -B1 recommended | /usr/bin/grep -v recommended | /usr/bin/awk '{print $2}' | /usr/bin/awk '{printf "%s ", $0}'`
osvers=`sw_vers -productVersion | awk -F. '{print $2}'`

if [[ $osvers -lt 8 ]]; then
/bin/echo "Script only for 10.8+ ONLY"
exit 1
elif [ "$SWULER" == "No new software available." ]; then
/bin/echo "$SWULER"
exit 1
elif [[ "$SWUL" == *"[restart]"* ]]; then
echo "Installing Updates that require Restart"
/usr/bin/sudo /usr/sbin/softwareupdate -d -a
/usr/libexec/PListBuddy -c "Copy CompletedProducts InstallAtLogout" /Library/Updates/index.plist
/usr/bin/touch /var/db/.SoftwareUpdateAtLogout
/bin/chmod og-r /var/db/.SoftwareUpdateAtLogout
/usr/libexec/PListBuddy -c "Add -RootInstallMode STRING YES" /var/db/.SoftwareUpdateOptions
/usr/libexec/PListBuddy -c "Add -SkipConfirm STRING YES" /var/db/.SoftwareUpdateOptions
/bin/chmod og-r /var/db/.SoftwareUpdateOptions
elif [[ "$SWUL" == *"[recommended]"* ]]; then
/bin/echo "Installing Updates that does not require Restart"
/usr/bin/sudo /usr/sbin/softwareupdate -i $NoRestartUpdates
fi
