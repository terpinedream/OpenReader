#!/bin/sh
# Amazon-Free Boot Installer
# Installs OpenReader as the default boot UI (replaces Amazon framework)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER_DIR="$(dirname "$SCRIPT_DIR")"
UPSTART_CONF="/etc/upstart/openreader-boot.conf"
SOURCE_CONF="$LAUNCHER_DIR/openreader-boot.conf"
BOOT_SCRIPT="$SCRIPT_DIR/boot-replacement.sh"

FBINK="/mnt/us/koreader/fbink"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Suspend framework to prevent UI interference
killall -STOP cvm 2>/dev/null || true
killall -STOP lipc-wait-event 2>/dev/null || true

# Clear screen aggressively
$FBINK -c
$FBINK -f
sleep 0.5

# Check if running as root, if not, re-exec with su
if [ "$(id -u)" != "0" ]; then
    # Not root, try to re-run with su
    $FBINK -c
    $FBINK -f
    $FBINK -y 10 -pmh "Requesting root permissions..."
    $FBINK -y 12 -pm "This installer needs root access to"
    $FBINK -y 13 -pm "modify system boot configuration."
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
$FBINK -f
sleep 0.3
$FBINK -y 5 -pmh "═══════════════════════════════════════"
$FBINK -y 6 -pmh "  AMAZON-FREE BOOT INSTALLER"
$FBINK -y 7 -pmh "═══════════════════════════════════════"
$FBINK -y 9 -pm ""
$FBINK -y 10 -pm "This will configure your Kindle to:"
$FBINK -y 11 -pm "• Boot to OpenReader by default"
$FBINK -y 12 -pm "• Suspend Amazon framework at startup"
$FBINK -y 13 -pm "• Keep KindleOS accessible via Settings"
$FBINK -y 14 -pm ""
$FBINK -y 15 -pm "WARNING:"
$FBINK -y 16 -pm "• Test manual launcher first!"
$FBINK -y 17 -pm "• Emergency: Delete via USB/SSH"
$FBINK -y 18 -pm "• Recovery info will be displayed"
$FBINK -y 19 -pm ""

# Check if already installed
if [ -f "$UPSTART_CONF" ]; then
    $FBINK -y 21 -pmh "ERROR: Already installed!"
    $FBINK -y 23 -pm "To reinstall, run uninstall first:"
    $FBINK -y 24 -pm "  Settings → Uninstall Amazon-Free Boot"
    $FBINK -y 26 -pm "Touch anywhere to exit..."
    sleep 5
    exit 1
fi

# Pre-flight checks
$FBINK -y 21 -pmh "Running pre-flight checks..."

# Check if launcher exists
if [ ! -f "$BOOT_SCRIPT" ]; then
    $FBINK -y 23 -pm "ERROR: ERROR: boot-replacement.sh not found!"
    $FBINK -y 24 -pm "   Path: $BOOT_SCRIPT"
    sleep 3
    exit 1
fi

# Check if upstart conf source exists
if [ ! -f "$SOURCE_CONF" ]; then
    $FBINK -y 23 -pm "ERROR: ERROR: openreader-boot.conf not found!"
    $FBINK -y 24 -pm "   Path: $SOURCE_CONF"
    sleep 3
    exit 1
fi

# Make boot script executable
chmod +x "$BOOT_SCRIPT"

$FBINK -y 23 -pm "OK: Boot script ready"
$FBINK -y 24 -pm "OK: Configuration file ready"
sleep 1

# Install upstart configuration
$FBINK -y 26 -pmh "Installing boot configuration..."

if cp "$SOURCE_CONF" "$UPSTART_CONF"; then
    chmod 644 "$UPSTART_CONF"
    $FBINK -y 28 -pm "OK: Installed: $UPSTART_CONF"
else
    $FBINK -y 28 -pm "ERROR: ERROR: Failed to copy configuration!"
    $FBINK -y 29 -pm "   Check permissions"
    sleep 3
    exit 1
fi

sleep 1

# Installation complete
$FBINK -c
$FBINK -f
sleep 0.3
$FBINK -y 5 -pmh "═══════════════════════════════════════"
$FBINK -y 6 -pmh "  INSTALLATION COMPLETE!"
$FBINK -y 7 -pmh "═══════════════════════════════════════"
$FBINK -y 9 -pm ""
$FBINK -y 10 -pm "OK: Amazon-Free Boot is now active"
$FBINK -y 11 -pm "OK: Next reboot will launch OpenReader"
$FBINK -y 12 -pm ""
$FBINK -y 13 -pmh "EMERGENCY RECOVERY:"
$FBINK -y 14 -pm ""
$FBINK -y 15 -pm "If something goes wrong:"
$FBINK -y 16 -pm ""
$FBINK -y 17 -pm "Method 1: USB Recovery"
$FBINK -y 18 -pm "  1. Connect Kindle via USB"
$FBINK -y 19 -pm "  2. Delete: /etc/upstart/"
$FBINK -y 20 -pm "            openreader-boot.conf"
$FBINK -y 21 -pm "  3. Eject and reboot"
$FBINK -y 22 -pm ""
$FBINK -y 23 -pm "Method 2: Create Override File"
$FBINK -y 24 -pm "  1. Create file: BOOT_KINDLEOS"
$FBINK -y 25 -pm "  2. Place in Kindle's root"
$FBINK -y 26 -pm "  3. Reboot"
$FBINK -y 27 -pm ""
$FBINK -y 28 -pm "Method 3: Settings Menu"
$FBINK -y 29 -pm "  Settings → Boot to KindleOS Once"
$FBINK -y 30 -pm ""
$FBINK -y 32 -pmh "READY TO REBOOT?"
$FBINK -y 33 -pm "Touch anywhere to reboot now..."

# Wait for touch
read -t 30 -p "" 2>/dev/null || true

$FBINK -c
$FBINK -f
sleep 0.3
$FBINK -y 15 -pmh "Rebooting to OpenReader..."
$FBINK -y 17 -pm "Please wait..."
sleep 2

# Resume framework before reboot
killall -CONT cvm 2>/dev/null || true
killall -CONT lipc-wait-event 2>/dev/null || true

/sbin/reboot

