#!/bin/sh
# OpenReader Boot Replacement Script
# Prevents Amazon framework from starting and launches OpenReader instead
# Part of the "Amazon-Free Boot" system

LAUNCHER_DIR="/mnt/us/extensions/openReader"
LOG_FILE="/var/tmp/openreader-boot.log"

# Logging function
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "=== OpenReader Boot Replacement Starting ==="

# Emergency Recovery System

# Check for USB override file (user can create this to boot to KindleOS)
if [ -f /mnt/us/BOOT_KINDLEOS ]; then
    log_msg "USB override detected: BOOT_KINDLEOS file exists"
    mv /mnt/us/BOOT_KINDLEOS /mnt/us/BOOT_KINDLEOS.used
    log_msg "Allowing framework to start normally"
    exit 0
fi

# Check for one-time KindleOS boot request (from settings menu)
if [ -f /var/tmp/boot-kindleos-once ]; then
    log_msg "One-time KindleOS boot requested from settings"
    rm /var/tmp/boot-kindleos-once
    log_msg "Allowing framework to start normally"
    exit 0
fi

# Boot failure tracking (prevents boot loops)
BOOT_COUNT_FILE="/var/tmp/openreader-boot-count"
BOOT_FAILED_FILE="/var/tmp/openreader-boot-failed"

if [ -f "$BOOT_FAILED_FILE" ]; then
    log_msg "Boot failure flag detected - skipping OpenReader"
    rm "$BOOT_FAILED_FILE"
    exit 0
fi

# Increment boot counter
BOOT_COUNT=$(cat "$BOOT_COUNT_FILE" 2>/dev/null || echo "0")
BOOT_COUNT=$((BOOT_COUNT + 1))
echo "$BOOT_COUNT" > "$BOOT_COUNT_FILE"
log_msg "Boot attempt #$BOOT_COUNT"

# Too many boots in 60 seconds = problem, fall back to KindleOS
if [ "$BOOT_COUNT" -gt 3 ]; then
    log_msg "ERROR: Too many boot attempts ($BOOT_COUNT) - failing safe to KindleOS"
    touch "$BOOT_FAILED_FILE"
    exit 0
fi

# Reset counter after successful 60-second uptime
(
    sleep 60
    echo "0" > "$BOOT_COUNT_FILE"
    log_msg "Boot count reset after 60s uptime"
) &

# System Initialization

log_msg "Stopping framework from starting..."

# Aggressively stop all framework-related services
stop lab126_gui 2>/dev/null || true
stop framework 2>/dev/null || true
stop pillow 2>/dev/null || true
stop blanket 2>/dev/null || true
stop cmd 2>/dev/null || true
stop phd 2>/dev/null || true
stop pmond 2>/dev/null || true
stop tmd 2>/dev/null || true
stop webreader 2>/dev/null || true
stop kfxreader 2>/dev/null || true

# Kill any already-running framework processes immediately
killall -STOP cvm 2>/dev/null || true
killall -STOP lipc-wait-event 2>/dev/null || true
killall -STOP framework 2>/dev/null || true
killall -STOP pillow 2>/dev/null || true

log_msg "Framework services stopped"

# Wait for system to settle
sleep 1

# Unlock input devices
if [ -e /proc/keypad ]; then
    echo unlock > /proc/keypad
    log_msg "Unlocked keypad"
fi

if [ -e /proc/fiveway ]; then
    echo unlock > /proc/fiveway
    log_msg "Unlocked fiveway"
fi

# Prevent screensaver
lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
log_msg "Disabled screensaver"

# Framework Keeper (Continuous Monitoring)

log_msg "Starting framework keeper..."

# Background process to keep framework components suspended
(
    while true; do
        # Check if we should pause (KOReader running)
        if [ ! -f /var/tmp/koreader-pause-keeper ]; then
            # No pause flag - do normal work
            # Suspend any framework components that try to start
            for service in cvm lipc-wait-event framework pillow webreader kfxreader; do
                if pidof "$service" >/dev/null 2>&1; then
                    killall -STOP "$service" 2>/dev/null
                fi
            done
        fi
        # If pause flag exists, skip suspension (KOReader manages its own services)
        sleep 5
    done
) &

KEEPER_PID=$!
echo "$KEEPER_PID" > /var/tmp/openreader-keeper.pid
log_msg "Framework keeper started (PID: $KEEPER_PID)"

# Launch OpenReader

log_msg "Launching OpenReader..."

# Ensure launcher directory exists
if [ ! -d "$LAUNCHER_DIR" ]; then
    log_msg "ERROR: Launcher directory not found: $LAUNCHER_DIR"
    log_msg "Falling back to KindleOS"
    kill "$KEEPER_PID" 2>/dev/null
    exit 0
fi

# Ensure launcher script exists and is executable
LAUNCHER_SCRIPT="$LAUNCHER_DIR/bin/touch-launcher.sh"
if [ ! -x "$LAUNCHER_SCRIPT" ]; then
    log_msg "ERROR: Launcher script not found or not executable: $LAUNCHER_SCRIPT"
    log_msg "Falling back to KindleOS"
    kill "$KEEPER_PID" 2>/dev/null
    exit 0
fi

# Mark that we're in boot mode (for launcher's service management)
export OPENREADER_BOOT_MODE=1
log_msg "Set OPENREADER_BOOT_MODE=1"

# Initialize state file
echo "RUNNING" > /var/tmp/openreader-state
log_msg "Initialized state file"

# OpenReader Watchdog (Monitors and Auto-Restarts)

log_msg "Starting OpenReader watchdog..."

# Get fbink path for watchdog
FBINK_PATH="/mnt/us/koreader/fbink"
[ ! -f "$FBINK_PATH" ] && FBINK_PATH="/usr/bin/fbink"

# Background watchdog process - state-aware
(
    while true; do
        sleep 3  # Check every 3 seconds
        
        # Check the state file
        STATE=$(cat /var/tmp/openreader-state 2>/dev/null || echo "RUNNING")
        
        
        # Simple check: is the launcher running?
        if ! pgrep -f touch-launcher.sh >/dev/null 2>&1; then
            # Launcher not running - check state
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: Launcher not running, STATE=$STATE" >> "$LOG_FILE"
            
            case "$STATE" in
                EXIT)
                    # Intentional exit to KindleOS - don't restart
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: Exited to KindleOS, stopping..." >> "$LOG_FILE"
                    rm -f /var/tmp/openreader-state
                    exit 0
                    ;;
                    
                KOREADER|KTERM)
                    # Application running - check more frequently
                    # Don't wait in a loop, just check again next cycle
                    ;;
                    
                RESTART)
                    # Explicit restart request
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: Restart requested..." >> "$LOG_FILE"
                    rm -f /var/tmp/openreader-state
                    killall -9 koreader 2>/dev/null
                    killall -9 reader.lua 2>/dev/null
                    killall -9 touch_reader 2>/dev/null
                    
                    "$FBINK_PATH" -c 2>/dev/null
                    "$FBINK_PATH" -y 15 -pm "OpenReader restarting..." 2>/dev/null
                    sleep 1
                    
                    cd "$LAUNCHER_DIR" 2>/dev/null || continue
                    echo "RUNNING" > /var/tmp/openreader-state
                    OPENREADER_BOOT_MODE=1 "$LAUNCHER_SCRIPT" &
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: OpenReader restarted" >> "$LOG_FILE"
                    ;;
                    
                *)
                    # Unknown state or crash - restart
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: Launcher crashed (state: $STATE), restarting..." >> "$LOG_FILE"
                    
                    rm -f /var/tmp/openreader-state
                    killall -9 touch_reader 2>/dev/null
                    
                    "$FBINK_PATH" -c 2>/dev/null
                    "$FBINK_PATH" -y 15 -pm "OpenReader restarting..." 2>/dev/null
                    sleep 1
                    
                    cd "$LAUNCHER_DIR" 2>/dev/null || continue
                    echo "RUNNING" > /var/tmp/openreader-state
                    OPENREADER_BOOT_MODE=1 "$LAUNCHER_SCRIPT" &
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog: OpenReader restarted" >> "$LOG_FILE"
                    ;;
            esac
        fi
    done
) &

WATCHDOG_PID=$!
echo "$WATCHDOG_PID" > /var/tmp/openreader-watchdog.pid
log_msg "Watchdog started (PID: $WATCHDOG_PID)"

# Launch OpenReader (Initial Start)

# Change to launcher directory
cd "$LAUNCHER_DIR" || exit 0

# Launch OpenReader
log_msg "Launching OpenReader (initial start)..."
"$LAUNCHER_SCRIPT" &

log_msg "OpenReader boot sequence complete"

# Keep this script running so watchdog stays alive
wait

