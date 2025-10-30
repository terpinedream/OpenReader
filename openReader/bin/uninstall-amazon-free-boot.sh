#!/bin/sh
# Amazon-Free Boot Uninstaller
# Removes OpenReader boot replacement and restores normal Kindle boot

UPSTART_CONF="/etc/upstart/openreader-boot.conf"
KEEPER_PID_FILE="/var/tmp/openreader-keeper.pid"
BOOT_COUNT_FILE="/var/tmp/openreader-boot-count"
BOOT_FAILED_FILE="/var/tmp/openreader-boot-failed"
BOOT_ONCE_FILE="/var/tmp/boot-kindleos-once"

# Colors/formatting for fbink
FBINK="/mnt/us/koreader/fbink"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Check if running as root, if not, re-exec with su
if [ "$(id -u)" != "0" ]; then
    # Not root, try to re-run with su
    $FBINK -c
    $FBINK -y 10 -pmh "Requesting root permissions..."
    $FBINK -y 12 -pm "This uninstaller needs root access to"
    $FBINK -y 13 -pm "remove system boot configuration."
    $FBINK -y 15 -pm "Attempting to elevate..."
    sleep 2
    
    # Re-execute this script with root privileges
    exec su -c "$0" root
    
    # If exec fails, show error
    $FBINK -c
    $FBINK -y 10 -pmh "ERROR: Could not elevate to root!"
    $FBINK -y 12 -pm "Please run manually:"
    $FBINK -y 13 -pm "  su"
    $FBINK -y 14 -pm "  $0"
    $FBINK -y 16 -pm "Touch anywhere to exit..."
    sleep 3
    exit 1
fi

$FBINK -c
$FBINK -y 5 -pmh "═══════════════════════════════════════"
$FBINK -y 6 -pmh "  AMAZON-FREE BOOT UNINSTALLER"
$FBINK -y 7 -pmh "═══════════════════════════════════════"
$FBINK -y 9 -pm ""
$FBINK -y 10 -pm "This will restore normal Kindle boot:"
$FBINK -y 11 -pm "• Remove OpenReader boot configuration"
$FBINK -y 12 -pm "• Restore Amazon framework startup"
$FBINK -y 13 -pm "• Clean up boot-related temporary files"
$FBINK -y 14 -pm ""
$FBINK -y 15 -pm "Note: OpenReader launcher will still be"
$FBINK -y 16 -pm "available via KUAL for manual use."
$FBINK -y 17 -pm ""

# Check if actually installed
if [ ! -f "$UPSTART_CONF" ]; then
    $FBINK -y 19 -pmh "ERROR: Not installed!"
    $FBINK -y 21 -pm "Amazon-Free Boot is not currently active."
    $FBINK -y 22 -pm "Nothing to uninstall."
    $FBINK -y 24 -pm "Touch anywhere to exit..."
    sleep 3
    exit 0
fi

$FBINK -y 19 -pmh "Removing boot configuration..."
sleep 1

# Kill framework keeper if running
if [ -f "$KEEPER_PID_FILE" ]; then
    KEEPER_PID=$(cat "$KEEPER_PID_FILE")
    if [ -n "$KEEPER_PID" ]; then
        kill "$KEEPER_PID" 2>/dev/null
        $FBINK -y 21 -pm "OK: Stopped framework keeper"
    fi
    rm "$KEEPER_PID_FILE"
fi

# Kill watchdog if running
WATCHDOG_PID_FILE="/var/tmp/openreader-watchdog.pid"
if [ -f "$WATCHDOG_PID_FILE" ]; then
    WATCHDOG_PID=$(cat "$WATCHDOG_PID_FILE")
    if [ -n "$WATCHDOG_PID" ]; then
        kill "$WATCHDOG_PID" 2>/dev/null
        $FBINK -y 22 -pm "OK: Stopped watchdog"
    fi
    rm "$WATCHDOG_PID_FILE"
fi

# Remove upstart configuration
if rm "$UPSTART_CONF"; then
    $FBINK -y 24 -pm "OK: Removed boot configuration"
else
    $FBINK -y 24 -pm "ERROR: ERROR: Failed to remove configuration!"
    $FBINK -y 25 -pm "   Check permissions"
    sleep 3
    exit 1
fi

# Clean up temporary files
rm -f "$BOOT_COUNT_FILE" 2>/dev/null
rm -f "$BOOT_FAILED_FILE" 2>/dev/null
rm -f "$BOOT_ONCE_FILE" 2>/dev/null
$FBINK -y 23 -pm "OK: Cleaned temporary files"

sleep 1

# Uninstallation complete
$FBINK -c
$FBINK -y 5 -pmh "═══════════════════════════════════════"
$FBINK -y 6 -pmh "  UNINSTALL COMPLETE!"
$FBINK -y 7 -pmh "═══════════════════════════════════════"
$FBINK -y 9 -pm ""
$FBINK -y 10 -pm "OK: Amazon-Free Boot has been removed"
$FBINK -y 11 -pm "OK: Next reboot will use normal Kindle UI"
$FBINK -y 12 -pm ""
$FBINK -y 13 -pm "OpenReader launcher is still available:"
$FBINK -y 14 -pm "  KUAL → Kindle Launcher"
$FBINK -y 15 -pm "           → Launch OpenReader"
$FBINK -y 16 -pm ""
$FBINK -y 17 -pm "To reinstall Amazon-Free Boot:"
$FBINK -y 18 -pm "  KUAL → Kindle Launcher"
$FBINK -y 19 -pm "           → Install Amazon-Free Boot"
$FBINK -y 20 -pm ""
$FBINK -y 22 -pmh "READY TO REBOOT?"
$FBINK -y 23 -pm "Touch anywhere to reboot now..."

# Wait for touch
read -t 30 -p "" 2>/dev/null || true

$FBINK -c
$FBINK -y 15 -pmh "Rebooting to normal Kindle UI..."
sleep 2

/sbin/reboot

