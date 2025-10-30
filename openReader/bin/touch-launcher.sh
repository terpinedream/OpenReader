#!/bin/sh
# Kindle Touch-Enabled Launcher - CLEAN UI VERSION
# Uses compiled touch_reader binary for real touch input

SCRIPT_DIR="$(dirname "$0")"
FBINK="/mnt/us/koreader/fbink"
TOUCH_READER="$SCRIPT_DIR/touch_reader"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Global state variables
FRONTLIGHT_ENABLED=0
FRONTLIGHT_LAST_LEVEL=600  # Default to 50% brightness (600/1200)

# Detect frontlight device path
detect_frontlight() {
    if [ -f /sys/class/backlight/max77696-bl/brightness ]; then
        echo "/sys/class/backlight/max77696-bl/brightness"
    elif [ -f /sys/class/backlight/fp9967-bl1/brightness ]; then
        echo "/sys/class/backlight/fp9967-bl1/brightness"
    elif [ -f /sys/class/backlight/mxc_msp430.0/brightness ]; then
        echo "/sys/class/backlight/mxc_msp430.0/brightness"
    else
        echo ""
    fi
}

FL_PATH=$(detect_frontlight)

# Check if touch_reader exists
if [ ! -f "$TOUCH_READER" ]; then
    $FBINK -c
    $FBINK -y 10 -pmh "Error: touch_reader not compiled!"
    $FBINK -y 12 -pm "Please compile the touch input binary"
    $FBINK -y 13 -pm "See: src/README.md for instructions"
    sleep 3
    exit 1
fi

# Stop Kindle services (KOReader method - use SIGSTOP to prevent auto-restart)
stop_services() {
    # Check if we're in boot mode (framework never started)
    if [ "$OPENREADER_BOOT_MODE" = "1" ]; then
        # Boot mode: Framework never started, just prevent screensaver
        FRAMEWORK_WAS_RUNNING=0
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
        return
    fi
    
    # Check if framework is actually running
    if pidof cvm >/dev/null 2>&1; then
        # Framework is running, suspend it
        FRAMEWORK_WAS_RUNNING=1
        
        # Prevent screen saver
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
        
        # Suspend (SIGSTOP) all framework processes
        # Using SIGSTOP instead of SIGKILL prevents init from restarting them
        killall -STOP cvm 2>/dev/null
        killall -STOP lipc-wait-event 2>/dev/null
        killall -STOP webreader 2>/dev/null
        killall -STOP kfxreader 2>/dev/null
        killall -STOP kfxview 2>/dev/null
        killall -STOP mesquite 2>/dev/null
        killall -STOP browserd 2>/dev/null
        
        # Suspend background services (from KOReader's TOGGLED_SERVICES)
        killall -STOP stored 2>/dev/null
        killall -STOP todo 2>/dev/null
        killall -STOP tmd 2>/dev/null
        killall -STOP rcm 2>/dev/null
        killall -STOP archive 2>/dev/null
        killall -STOP scanner 2>/dev/null
        killall -STOP otav3 2>/dev/null
        killall -STOP otaupd 2>/dev/null
        killall -STOP volumd 2>/dev/null
        
        # Ensure clean framebuffer
        echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
        
        # Small delay to ensure processes are fully stopped
        sleep 0.5
    else
        # Framework not running (we're in boot mode)
        FRAMEWORK_WAS_RUNNING=0
        lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
    fi
}

# Restore Kindle services (resume suspended processes)
restore_services() {
    # Signal watchdog NOT to restart (permanent exit to KindleOS)
    echo "EXIT" > /var/tmp/openreader-state
    
    # Kill touch reader
    killall -TERM touch_reader 2>/dev/null
    
    # Check if we're in boot mode
    if [ "$OPENREADER_BOOT_MODE" = "1" ]; then
        # Boot mode: Don't restore framework, we're staying in OpenReader
        # Just clean up
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
        return
    fi
    
    # Check if framework was actually running before
    if [ "$FRAMEWORK_WAS_RUNNING" = "1" ]; then
        # Framework was running, restore it
        
        # Re-enable screen saver
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
        
        # Resume (SIGCONT) all suspended processes
        killall -CONT cvm 2>/dev/null
        killall -CONT lipc-wait-event 2>/dev/null
        killall -CONT webreader 2>/dev/null
        killall -CONT kfxreader 2>/dev/null
        killall -CONT kfxview 2>/dev/null
        killall -CONT mesquite 2>/dev/null
        killall -CONT browserd 2>/dev/null
        killall -CONT stored 2>/dev/null
        killall -CONT todo 2>/dev/null
        killall -CONT tmd 2>/dev/null
        killall -CONT rcm 2>/dev/null
        killall -CONT archive 2>/dev/null
        killall -CONT scanner 2>/dev/null
        killall -CONT otav3 2>/dev/null
        killall -CONT otaupd 2>/dev/null
        killall -CONT volumd 2>/dev/null
        
        # Refresh display
        echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
    else
        # Framework wasn't running, don't restore anything
        lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
    fi
}

# Get screen dimensions
get_screen_size() {
    # Default to Paperwhite resolution (758x1024)
    SCREEN_WIDTH=758
    SCREEN_HEIGHT=1024
    
    # Try to detect actual dimensions
    if [ -f /sys/class/graphics/fb0/virtual_size ]; then
        DIMS=$(cat /sys/class/graphics/fb0/virtual_size)
        SCREEN_WIDTH=$(echo "$DIMS" | cut -d',' -f1)
        SCREEN_HEIGHT=$(echo "$DIMS" | cut -d',' -f2)
    fi
    
    # Calculate line positions for 758x1024 (27px per line)
    # Screen height: 1024px / 27px = ~38 lines
    TOOLBAR_LINE=$((SCREEN_HEIGHT / 27 - 3))  # 3 lines from bottom
}

# Draw the menu (OPTIMIZED FOR 758x1024 - FULL SCREEN)
draw_menu() {
    SELECTED=$1
    
    $FBINK -c
    
    # ═══════════════════════════════════════════════════
    # BANNER - Centered with padding (lines 5-16)
    # ═══════════════════════════════════════════════════
    $FBINK -y 5 -pm "██████╗ ██████╗ ███████╗███╗   ██╗"
    $FBINK -y 6 -pm "██╔═══██╗██╔══██╗██╔════╝████╗  ██║"
    $FBINK -y 7 -pm "██║   ██║██████╔╝█████╗  ██╔██╗ ██║"
    $FBINK -y 8 -pm "██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║"
    $FBINK -y 9 -pm "╚██████╔╝██║     ███████╗██║ ╚████║"
    $FBINK -y 10 -pm " ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝"
    $FBINK -y 11 -pm "██████╗ ███████╗ █████╗ ██████╗"
    $FBINK -y 12 -pm "██╔══██╗██╔════╝██╔══██╗██╔══██╗"
    $FBINK -y 13 -pm "██████╔╝█████╗  ███████║██║  ██║"
    $FBINK -y 14 -pm "██╔══██╗██╔══╝  ██╔══██║██║  ██║"
    $FBINK -y 15 -pm "██║  ██║███████╗██║  ██║██████╔╝"
    $FBINK -y 16 -pm "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝"
    
    # Random tagline (centered) - using case for sh compatibility
    RANDOM_NUM=$(($(date +%s) % 11))
    case $RANDOM_NUM in
        0) TAGLINE="Open Source The World!" ;;
        1) TAGLINE="Sorry, Jeff :(" ;;
        2) TAGLINE="It's Free!" ;;
        3) TAGLINE="Whatcha Readin?" ;;
        4) TAGLINE="Welcome Back!" ;;
        5) TAGLINE="terpinedream was here" ;;
        6) TAGLINE="For books and stuff" ;;
        7) TAGLINE="Now Without Two Day Shipping." ;;
        8) TAGLINE="Wow!" ;;
        9) TAGLINE="Is this thing on?" ;;
        10) TAGLINE="Thank Your Local Devs!" ;;
    esac
    
    $FBINK -y 18 -pm ""
    $FBINK -y 19 -pm "            $TAGLINE"
    
    # ═══════════════════════════════════════════════════
    # MAIN BUTTONS - Shifted down to make room for tagline
    # ═══════════════════════════════════════════════════
    
    # Button 1: KOReader (lines 21-24)
    if [ "$SELECTED" = "1" ]; then
        $FBINK -y 21 -pmh "╔══════════════════════════════════════╗"
        $FBINK -y 22 -pmh "║     [BOOK]  KOREADER                 ║"
        $FBINK -y 23 -pmh "║             Open eBook Reader        ║"
        $FBINK -y 24 -pmh "╚══════════════════════════════════════╝"
    else
        $FBINK -y 21 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 22 -pm "│     [BOOK]  KOREADER                 │"
        $FBINK -y 23 -pm "│             Open eBook Reader        │"
        $FBINK -y 24 -pm "└──────────────────────────────────────┘"
    fi
    
    # Button 2: System Info (lines 27-30)
    if [ "$SELECTED" = "2" ]; then
        $FBINK -y 27 -pmh "╔══════════════════════════════════════╗"
        $FBINK -y 28 -pmh "║     [INFO]  SYSTEM INFO              ║"
        $FBINK -y 29 -pmh "║             Device Status & Details  ║"
        $FBINK -y 30 -pmh "╚══════════════════════════════════════╝"
    else
        $FBINK -y 27 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 28 -pm "│     [INFO]  SYSTEM INFO              │"
        $FBINK -y 29 -pm "│             Device Status & Details  │"
        $FBINK -y 30 -pm "└──────────────────────────────────────┘"
    fi
    
    # Button 3: Terminal (lines 33-36)
    if [ "$SELECTED" = "3" ]; then
        $FBINK -y 33 -pmh "╔══════════════════════════════════════╗"
        $FBINK -y 34 -pmh "║     [TERM]  TERMINAL                 ║"
        $FBINK -y 35 -pmh "║             Open Command Shell       ║"
        $FBINK -y 36 -pmh "╚══════════════════════════════════════╝"
    else
        $FBINK -y 33 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 34 -pm "│     [TERM]  TERMINAL                 │"
        $FBINK -y 35 -pm "│             Open Command Shell       │"
        $FBINK -y 36 -pm "└──────────────────────────────────────┘"
    fi
    
    # Button 4: File Browser (lines 39-42)
    if [ "$SELECTED" = "4" ]; then
        $FBINK -y 39 -pmh "╔══════════════════════════════════════╗"
        $FBINK -y 40 -pmh "║     [FILE]  FILE BROWSER             ║"
        $FBINK -y 41 -pmh "║             Browse Documents         ║"
        $FBINK -y 42 -pmh "╚══════════════════════════════════════╝"
    else
        $FBINK -y 39 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 40 -pm "│     [FILE]  FILE BROWSER             │"
        $FBINK -y 41 -pm "│             Browse Documents         │"
        $FBINK -y 42 -pm "└──────────────────────────────────────┘"
    fi
    
    # Button 5: Settings (lines 45-48)
    if [ "$SELECTED" = "5" ]; then
        $FBINK -y 45 -pmh "╔══════════════════════════════════════╗"
        $FBINK -y 46 -pmh "║     [GEAR]  SETTINGS                 ║"
        $FBINK -y 47 -pmh "║             Configure System         ║"
        $FBINK -y 48 -pmh "╚══════════════════════════════════════╝"
    else
        $FBINK -y 45 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 46 -pm "│     [GEAR]  SETTINGS                 │"
        $FBINK -y 47 -pm "│             Configure System         │"
        $FBINK -y 48 -pm "└──────────────────────────────────────┘"
    fi
    
    # Note: Button 6 slot reserved for Settings menu "Exit to Kindle OS"
    # This keeps main menu at 5 buttons, settings at 5 buttons + toolbar
    
    # ═══════════════════════════════════════════════════
    # BOTTOM TOOLBAR - ABSOLUTE BOTTOM (lines 51-54)
    # ═══════════════════════════════════════════════════
    $FBINK -y 51 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 52 -pm "┌───────┬───────┬───────┬───────┬──────┐"
    $FBINK -y 53 -pm "│[LIGHT]│[WIFI ]│[REFRH]│[BOOT ]│[OFF ]│"
    $FBINK -y 54 -pm "└───────┴───────┴───────┴───────┴──────┘"
}

# Determine which button was touched
get_button_from_coords() {
    X=$1
    Y=$2
    
    # ═══════════════════════════════════════════════════════════════
    # CALIBRATED TOUCH REGIONS - Oct 27, 2025 15:00:23 AST
    # Based on 35-point corner calibration with EXACT UI match
    # See: CALIBRATION_ANALYSIS.md for full details
    # ═══════════════════════════════════════════════════════════════
    
    # Check if touch is in TOOLBAR region (Y > 850)
    if [ "$Y" -gt 850 ]; then
        # TOOLBAR X-AXIS DIVISIONS (Y: 858-870)
        # Button 1 [LIGHT]: X 98-173   (avg: 139)
        # Button 2 [WIFI]:  X 219-302  (avg: 258)
        # Button 3 [REFRH]: X 351-415  (avg: 383)
        # Button 4 [BOOT]:  X 477-550  (avg: 513)
        # Button 5 [OFF]:   X 601-668  (avg: 635)
        #
        # Thresholds (midpoints between buttons):
        # - LIGHT|WIFI:   (173+219)/2 = 196
        # - WIFI|REFRH:   (302+351)/2 = 326
        # - REFRH|BOOT:   (415+477)/2 = 446
        # - BOOT|OFF:     (550+601)/2 = 575
        
        if [ "$X" -lt 196 ]; then
            echo "toolbar_light"
        elif [ "$X" -lt 326 ]; then
            echo "toolbar_wifi"
        elif [ "$X" -lt 446 ]; then
            echo "toolbar_refresh"
        elif [ "$X" -lt 575 ]; then
            echo "toolbar_reboot"
        else
            echo "toolbar_poweroff"
        fi
        return
    fi
    
    # MAIN BUTTONS Y-AXIS (all buttons span X: ~61-702)
    # Button 1 [BOOK]: Y 344-400  (height: 56px, midpoint: 372)
    # Button 2 [INFO]: Y 452-503  (height: 51px, midpoint: 477)
    # Button 3 [TERM]: Y 550-601  (height: 51px, midpoint: 575)
    # Button 4 [FILE]: Y 645-692  (height: 47px, midpoint: 668)
    # Button 5 [GEAR]: Y 735-796  (height: 61px, midpoint: 765)
    #
    # Thresholds (midpoints between buttons):
    # - BOOK|INFO:   (400+452)/2 = 426
    # - INFO|TERM:   (503+550)/2 = 526
    # - TERM|FILE:   (601+645)/2 = 623
    # - FILE|GEAR:   (692+735)/2 = 713
    
    if [ "$Y" -lt 426 ]; then
        echo "1"  # KOReader
    elif [ "$Y" -lt 526 ]; then
        echo "2"  # System Info
    elif [ "$Y" -lt 623 ]; then
        echo "3"  # Terminal
    elif [ "$Y" -lt 713 ]; then
        echo "4"  # File Browser
    elif [ "$Y" -lt 850 ]; then
        echo "5"  # Settings
    else
        echo "unknown"  # Shouldn't reach here
    fi
}

# Show system info (with ASCII banner)
show_system_info() {
    $FBINK -c
    
    # Kindle figlet banner - moved down with more spacing
    $FBINK -y 8 -pm ""
    $FBINK -y 9 -pm " _  ___           _ _      "
    $FBINK -y 10 -pm "| |/ (_)_ __   __| | | ___ "
    $FBINK -y 11 -pm "| ' /| | '_ \\ / _\` | |/ _ \\"
    $FBINK -y 12 -pm "| . \\| | | | | (_| | |  __/"
    $FBINK -y 13 -pm "|_|\\_\\_|_| |_|\\__,_|_|\\___|"
    
    # Get system information
    MODEL=$(cat /proc/usid 2>/dev/null | cut -c4- || echo "Unknown")
    KERNEL=$(uname -r)
    UPTIME=$(uptime | awk '{print $3}' | sed 's/,//')
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f/%.0f MB", $3,$2}')
    STORAGE=$(df -h /mnt/us | tail -n 1 | awk '{print $3" / "$2" ("$5")"}')
    
    # Battery info
    if [ -f /sys/class/power_supply/bd71827_bat/capacity ]; then
        BATTERY=$(cat /sys/class/power_supply/bd71827_bat/capacity 2>/dev/null || echo "N/A")
        BATTERY="$BATTERY%"
    else
        BATTERY="N/A"
    fi
    
    # Display system information with spacing
    $FBINK -y 16 -pm ""
    $FBINK -y 17 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 19 -pm "Device:  Kindle $MODEL"
    $FBINK -y 20 -pm "Kernel:  $KERNEL"
    $FBINK -y 21 -pm "Battery: $BATTERY"
    $FBINK -y 23 -pm "Uptime:  $UPTIME"
    $FBINK -y 24 -pm "Memory:  $MEMORY"
    $FBINK -y 25 -pm "Storage: $STORAGE"
    $FBINK -y 27 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 28 -pm "Touch anywhere to return..."
    
    # Wait for touch
    "$TOUCH_READER" /dev/input/event1 2>/dev/null >/dev/null
}

# Settings menu (EXACT UI MATCH to main menu for coordinate reuse)
show_settings() {
    while true; do
        $FBINK -c
        
        # ═══════════════════════════════════════════════════
        # BANNER - Same as main menu (lines 5-16)
        # ═══════════════════════════════════════════════════
        $FBINK -y 5 -pm "██████╗ ██████╗ ███████╗███╗   ██╗"
        $FBINK -y 6 -pm "██╔═══██╗██╔══██╗██╔════╝████╗  ██║"
        $FBINK -y 7 -pm "██║   ██║██████╔╝█████╗  ██╔██╗ ██║"
        $FBINK -y 8 -pm "██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║"
        $FBINK -y 9 -pm "╚██████╔╝██║     ███████╗██║ ╚████║"
        $FBINK -y 10 -pm " ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝"
        $FBINK -y 11 -pm "██████╗ ███████╗ █████╗ ██████╗"
        $FBINK -y 12 -pm "██╔══██╗██╔════╝██╔══██╗██╔══██╗"
        $FBINK -y 13 -pm "██████╔╝█████╗  ███████║██║  ██║"
        $FBINK -y 14 -pm "██╔══██╗██╔══╝  ██╔══██║██║  ██║"
        $FBINK -y 15 -pm "██║  ██║███████╗██║  ██║██████╔╝"
        $FBINK -y 16 -pm "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝"
        
        # Tagline replacement
        $FBINK -y 18 -pm ""
        $FBINK -y 19 -pm "                Settings!"
        
        # ═══════════════════════════════════════════════════
        # STATUS CHECKS
        # ═══════════════════════════════════════════════════
        
        # Check frontlight status and build slider
        FL_BRIGHT=0
        FL_MAX_HARDWARE=1200  # Kindle display max brightness
        FL_SLIDER_WIDTH=24    # Visual slider width in characters
        
        if [ -n "$FL_PATH" ] && [ -f "$FL_PATH" ]; then
            FL_BRIGHT=$(cat "$FL_PATH" 2>/dev/null || echo "0")
        fi
        
        # Build frontlight slider (24 chars wide)
        # Map hardware brightness (0-1200) to visual slider (0-24)
        FL_FILLED=$((FL_BRIGHT * FL_SLIDER_WIDTH / FL_MAX_HARDWARE))
        if [ $FL_FILLED -gt $FL_SLIDER_WIDTH ]; then FL_FILLED=$FL_SLIDER_WIDTH; fi
        FL_EMPTY=$((FL_SLIDER_WIDTH - FL_FILLED))
        
        # Build slider bar
        FL_SLIDER=""
        i=0
        while [ $i -lt $FL_FILLED ]; do
            FL_SLIDER="${FL_SLIDER}█"
            i=$((i + 1))
        done
        i=0
        while [ $i -lt $FL_EMPTY ]; do
            FL_SLIDER="${FL_SLIDER}░"
            i=$((i + 1))
        done
        
        # WiFi status removed - button is now static
        
        # ═══════════════════════════════════════════════════
        # SETTINGS BUTTONS - EXACT SAME LINES AS MAIN MENU
        # ═══════════════════════════════════════════════════
        
        # Button 1: Frontlight Slider (lines 21-24 - same as main Button 1)
        $FBINK -y 21 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 22 -pm "│                                      │"
        $FBINK -y 23 -pm "│  [LIGHT] [$FL_SLIDER]  │"
        $FBINK -y 24 -pm "└──────────────────────────────────────┘"
        
        # Button 2: WiFi Settings (lines 27-30 - same as main Button 2)
        $FBINK -y 27 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 28 -pm "│  [WIFI]  WI-FI SETTINGS              │"
        $FBINK -y 29 -pm "│          Manage Wireless Network     │"
        $FBINK -y 30 -pm "└──────────────────────────────────────┘"
        
        # Button 3: Boot to KindleOS (or Reboot if not in boot mode)
        if [ "$OPENREADER_BOOT_MODE" = "1" ]; then
            # Boot mode: Offer to boot to KindleOS once
            $FBINK -y 33 -pm "┌──────────────────────────────────────┐"
            $FBINK -y 34 -pm "│  [KINDLE] BOOT TO KINDLEOS ONCE      │"
            $FBINK -y 35 -pm "│           Restart to Stock UI        │"
            $FBINK -y 36 -pm "└──────────────────────────────────────┘"
        else
            # Normal mode: Regular reboot
            $FBINK -y 33 -pm "┌──────────────────────────────────────┐"
            $FBINK -y 34 -pm "│     [BOOT]  REBOOT DEVICE            │"
            $FBINK -y 35 -pm "│             Restart Kindle           │"
            $FBINK -y 36 -pm "└──────────────────────────────────────┘"
        fi
        
        # Button 4: Power Off (lines 39-42 - same as main Button 4)
        $FBINK -y 39 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 40 -pm "│     [PWROFF] POWER OFF               │"
        $FBINK -y 41 -pm "│              Shut Down Kindle        │"
        $FBINK -y 42 -pm "└──────────────────────────────────────┘"
        
        # Button 5: Exit to Kindle OS (lines 45-48 - same as main Button 5)
        $FBINK -y 45 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 46 -pm "│     [EXIT]  EXIT TO KINDLE OS        │"
        $FBINK -y 47 -pm "│             Return to Stock UI       │"
        $FBINK -y 48 -pm "└──────────────────────────────────────┘"
        
        # ═══════════════════════════════════════════════════
        # BOTTOM TOOLBAR - SAME AS MAIN MENU (lines 51-54)
        # ═══════════════════════════════════════════════════
        $FBINK -y 51 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        $FBINK -y 52 -pm "┌───────┬───────┬───────┬───────┬──────┐"
        $FBINK -y 53 -pm "│[LIGHT]│[WIFI ]│[REFRH]│[BOOT ]│[BACK]│"
        $FBINK -y 54 -pm "└───────┴───────┴───────┴───────┴──────┘"
        
        # Get touch input
        COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
        X=$(echo "$COORDS" | cut -d',' -f1)
        Y=$(echo "$COORDS" | cut -d',' -f2)
        
        # ═══════════════════════════════════════════════════
        # USE EXACT SAME COORDINATE DETECTION AS MAIN MENU
        # ═══════════════════════════════════════════════════
        BUTTON=$(get_button_from_coords "$X" "$Y")
        
        # Handle toolbar buttons (same as main menu)
        case "$BUTTON" in
            toolbar_light)
                toggle_frontlight
                continue
                ;;
            toolbar_wifi)
                toggle_wifi
                continue
                ;;
            toolbar_refresh)
                # Refresh display
                continue
                ;;
            toolbar_reboot)
                reboot_system
                ;;
            toolbar_poweroff)
                # Change last toolbar button to "Back" in settings
                # So toolbar_poweroff becomes "Back to main menu"
                return
                ;;
        esac
        
        # Handle main buttons (mapped to settings actions)
        case "$BUTTON" in
            1)
                # Button 1: Frontlight Slider
                # CALIBRATED: Oct 27, 2025 16:22:10 AST
                # Precise slider boundaries from 2-point calibration
                # Start: X=256, End: X=649, Width: 393px
                if [ -n "$FL_PATH" ] && [ -f "$FL_PATH" ]; then
                    # Calculate brightness from X position
                    # X range: 256-649 (393px), map to 0-1200
                    X_OFFSET=$((X - 256))
                    if [ $X_OFFSET -lt 0 ]; then X_OFFSET=0; fi
                    if [ $X_OFFSET -gt 393 ]; then X_OFFSET=393; fi
                    
                    # Calculate brightness (0-1200)
                    NEW_BRIGHT=$((X_OFFSET * 1200 / 393))
                    if [ $NEW_BRIGHT -lt 0 ]; then NEW_BRIGHT=0; fi
                    if [ $NEW_BRIGHT -gt 1200 ]; then NEW_BRIGHT=1200; fi
                    
                    # Set new brightness
                    echo "$NEW_BRIGHT" > "$FL_PATH" 2>/dev/null
                fi
                sleep 0.2
                ;;
            2)
                # Button 2: Open Network Manager
                show_network_manager
                ;;
            3)
                # Button 3: Boot to KindleOS Once / Reboot
                if [ "$OPENREADER_BOOT_MODE" = "1" ]; then
                    # Boot mode: Set flag and reboot to KindleOS once
                    $FBINK -c
                    $FBINK -y 10 -pmh "⚠️  BOOTING TO KINDLEOS"
                    $FBINK -y 12 -pm "Next boot will use Amazon UI"
                    $FBINK -y 13 -pm "After that, OpenReader will resume"
                    sleep 2
                    
                    # Kill the framework keeper
                    KEEPER_PID=$(cat /var/tmp/openreader-keeper.pid 2>/dev/null)
                    [ -n "$KEEPER_PID" ] && kill "$KEEPER_PID" 2>/dev/null
                    
                    # Create one-time boot override
                    touch /var/tmp/boot-kindleos-once
                    
                    # Reboot
                    /sbin/reboot
                else
                    # Normal mode: Regular reboot
                    $FBINK -c
                    $FBINK -y 12 -pmh "⚠️  REBOOTING..."
                    sleep 2
                    restore_services
                    /sbin/reboot
                fi
                ;;
            4)
                # Button 4: Power Off
                $FBINK -c
                $FBINK -y 12 -pmh "⚠️  POWERING OFF..."
                sleep 2
                restore_services
                /sbin/poweroff
                ;;
            5)
                # Button 5: Exit to Kindle OS
                restore_services
                exit 0
                ;;
            unknown)
                # Invalid touch
                ;;
        esac
        
        sleep 0.2
    done
}

# Launch KOReader (no framework version)
launch_koreader() {
    if [ -f "/mnt/us/koreader/koreader.sh" ]; then
        # Kill our touch reader FIRST - critical to prevent conflicts
        killall -9 touch_reader 2>/dev/null
        
        # Signal watchdog NOT to restart (intentional exit for KOReader)
        echo "KOREADER" > /var/tmp/openreader-state
        
        # CRITICAL: Tell framework keeper to stop interfering
        # KOReader needs framework services to NOT be continuously suspended
        touch /var/tmp/koreader-pause-keeper
        
        # Show launching message
        $FBINK -c
        $FBINK -y 12 -pmh "Launching KOReader..."
        sleep 1
        
        # Create a launcher script that will run after we exit
        cat > /var/tmp/launch-koreader.sh << 'KOREADER_EOF'
#!/bin/sh
# Wait for OpenReader to fully exit
sleep 3

# Clear screen
/mnt/us/koreader/fbink -c 2>/dev/null

# Create a stub 'start' command that does nothing
# This prevents koreader.sh from hanging when trying to restart services
cat > /tmp/start << 'STUBEOF'
#!/bin/sh
# Stub start command - does nothing
exit 0
STUBEOF
chmod +x /tmp/start
export PATH="/tmp:$PATH"

# Launch KOReader in background so we can monitor it
cd /mnt/us/koreader
./koreader.sh &

KOREADER_PID=$!

# Wait for KOReader to actually start (reader.lua to appear)
STARTUP_WAIT=0
while [ $STARTUP_WAIT -lt 15 ]; do
    if pgrep -f "reader.lua" >/dev/null 2>&1; then
        break
    fi
    sleep 1
    STARTUP_WAIT=$((STARTUP_WAIT + 1))
done

if [ $STARTUP_WAIT -ge 15 ]; then
    kill -9 $KOREADER_PID 2>/dev/null
    echo "RESTART" > /var/tmp/openreader-state
    rm -f /var/tmp/koreader-pause-keeper
    rm -f /var/tmp/launch-koreader.sh
    exit 1
fi

# Now monitor for exit

while true; do
    sleep 2
    
    # Check if koreader.sh is still running
    if ! kill -0 $KOREADER_PID 2>/dev/null; then
        break
    fi
    
    # Check if reader.lua is running
    if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
        
        # Wait 5 seconds to see if it's just slow cleanup
        sleep 5
        
        if ! pgrep -f "reader.lua" >/dev/null 2>&1; then
            # Still no reader.lua - KOReader has exited but script is hung
            
            # Force kill everything
            kill -9 $KOREADER_PID 2>/dev/null
            killall -9 koreader 2>/dev/null
            killall -9 reader.lua 2>/dev/null
            break
        else
        fi
    fi
done

# Additional cleanup

killall -9 reader.lua 2>/dev/null

killall -9 koreader 2>/dev/null

# Remove stub commands
rm -f /tmp/start

# Signal restart FIRST (before any fbink that might hang)
echo "RESTART" > /var/tmp/openreader-state

# Remove keeper pause flag
rm -f /var/tmp/koreader-pause-keeper

# DON'T show any fbink message - just exit immediately
# The watchdog will show the message

# Clean up this script
rm -f /var/tmp/launch-koreader.sh

# Force exit - no delays, no fbink, nothing
exec 1>&-
exec 2>&-
exit 0
KOREADER_EOF
        
        chmod +x /var/tmp/launch-koreader.sh
        
        # Launch in background, detached from this process
        /var/tmp/launch-koreader.sh </dev/null >/dev/null 2>&1 &
        
        # Exit launcher IMMEDIATELY - critical to free up resources
        exit 0
    else
        $FBINK -c
        $FBINK -y 10 -pmh "KOReader not installed!"
        $FBINK -y 12 -pm "Install from: koreader.rocks"
        $FBINK -y 14 -pm "Touch anywhere to return..."
        "$TOUCH_READER" /dev/input/event1 2>/dev/null >/dev/null
    fi
}

# TOOLBAR BUTTON HANDLERS

# Toggle frontlight (with memory)
toggle_frontlight() {
    if [ -z "$FL_PATH" ]; then
        $FBINK -c
        $FBINK -y 15 -pmh "Frontlight not detected!"
        sleep 1
        return
    fi
    
    CURRENT=$(cat "$FL_PATH" 2>/dev/null || echo "0")
    
    if [ "$CURRENT" -eq 0 ]; then
        # Turn ON - restore last level
        echo "$FRONTLIGHT_LAST_LEVEL" > "$FL_PATH" 2>/dev/null
        FRONTLIGHT_ENABLED=1
    else
        # Turn OFF - remember current level
        FRONTLIGHT_LAST_LEVEL=$CURRENT
        echo 0 > "$FL_PATH" 2>/dev/null
        FRONTLIGHT_ENABLED=0
    fi
}

# Toggle WiFi
toggle_wifi() {
    if ! command -v lipc-get-prop >/dev/null 2>&1; then
        return
    fi
    
    if lipc-get-prop com.lab126.wifid cmState 2>/dev/null | grep -q CONNECTED; then
        lipc-set-prop com.lab126.cmd wirelessEnable 0 2>/dev/null
    else
        lipc-set-prop com.lab126.cmd wirelessEnable 1 2>/dev/null
    fi
}

# Network Manager UI (EXACT UI MATCH for coordinate reuse)
show_network_manager() {
    while true; do
        $FBINK -c
        
        # ═══════════════════════════════════════════════════
        # BANNER - Same as main menu (lines 5-16)
        # ═══════════════════════════════════════════════════
        $FBINK -y 5 -pm "██████╗ ██████╗ ███████╗███╗   ██╗"
        $FBINK -y 6 -pm "██╔═══██╗██╔══██╗██╔════╝████╗  ██║"
        $FBINK -y 7 -pm "██║   ██║██████╔╝█████╗  ██╔██╗ ██║"
        $FBINK -y 8 -pm "██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║"
        $FBINK -y 9 -pm "╚██████╔╝██║     ███████╗██║ ╚████║"
        $FBINK -y 10 -pm " ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝"
        $FBINK -y 11 -pm "██████╗ ███████╗ █████╗ ██████╗"
        $FBINK -y 12 -pm "██╔══██╗██╔════╝██╔══██╗██╔══██╗"
        $FBINK -y 13 -pm "██████╔╝█████╗  ███████║██║  ██║"
        $FBINK -y 14 -pm "██╔══██╗██╔══╝  ██╔══██║██║  ██║"
        $FBINK -y 15 -pm "██║  ██║███████╗██║  ██║██████╔╝"
        $FBINK -y 16 -pm "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝"
        
        $FBINK -y 18 -pm ""
        $FBINK -y 19 -pm "           Network Manager"
        
        # ═══════════════════════════════════════════════════
        # GET NETWORK STATUS
        # ═══════════════════════════════════════════════════
        
        # Get current connection info
        WIFI_STATE=$(lipc-get-prop com.lab126.wifid cmState 2>/dev/null || echo "UNKNOWN")
        WIFI_ENABLED=$(lipc-get-prop com.lab126.wifid enable 2>/dev/null || echo "0")
        
        if [ "$WIFI_STATE" = "CONNECTED" ]; then
            CURRENT_SSID=$(lipc-get-prop com.lab126.wifid currentEssid 2>/dev/null || echo "Unknown")
            SIGNAL=$(lipc-get-prop com.lab126.wifid signalStrength 2>/dev/null || echo "0/5")
            WIFI_STATUS="Connected: $CURRENT_SSID ($SIGNAL)"
        elif [ "$WIFI_ENABLED" = "1" ]; then
            WIFI_STATUS="WiFi On - Not Connected"
        else
            WIFI_STATUS="WiFi Disabled"
        fi
        
        # ═══════════════════════════════════════════════════
        # NETWORK BUTTONS - EXACT SAME LINES AS MAIN MENU
        # ═══════════════════════════════════════════════════
        
        # Button 1: Current Status (lines 21-24)
        # No box - just display status as text
        $FBINK -y 21 -pm ""
        $FBINK -y 22 -pmh "   CURRENT STATUS:"
        $FBINK -y 23 -pm "   $WIFI_STATUS"
        $FBINK -y 24 -pm ""
        
        # Button 2: Enable/Disable WiFi (lines 27-30)
        # Static text that doesn't change based on state
        $FBINK -y 27 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 28 -pm "│  [POWER] TOGGLE WI-FI                │"
        $FBINK -y 29 -pm "│          Enable / Disable Radio      │"
        $FBINK -y 30 -pm "└──────────────────────────────────────┘"
        
        # Button 3: Scan Networks (lines 33-36)
        $FBINK -y 33 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 34 -pm "│  [SCAN]  SCAN FOR NETWORKS           │"
        $FBINK -y 35 -pm "│          Refresh WiFi List           │"
        $FBINK -y 36 -pm "└──────────────────────────────────────┘"
        
        # Button 4: Reconnect (lines 39-42)
        $FBINK -y 39 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 40 -pm "│  [LINK]  RECONNECT                   │"
        $FBINK -y 41 -pm "│          Reconnect to Last Network   │"
        $FBINK -y 42 -pm "└──────────────────────────────────────┘"
        
        # Button 5: Back to Settings (lines 45-48)
        $FBINK -y 45 -pm "┌──────────────────────────────────────┐"
        $FBINK -y 46 -pm "│  [BACK]  BACK TO SETTINGS            │"
        $FBINK -y 47 -pm "│          Return to Settings Menu     │"
        $FBINK -y 48 -pm "└──────────────────────────────────────┘"
        
        # ═══════════════════════════════════════════════════
        # BOTTOM TOOLBAR - SAME AS MAIN MENU (lines 51-54)
        # ═══════════════════════════════════════════════════
        $FBINK -y 51 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        $FBINK -y 52 -pm "┌───────┬───────┬───────┬───────┬──────┐"
        $FBINK -y 53 -pm "│[LIGHT]│[WIFI ]│[REFRH]│[BOOT ]│[BACK]│"
        $FBINK -y 54 -pm "└───────┴───────┴───────┴───────┴──────┘"
        
        # Get touch input
        COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
        X=$(echo "$COORDS" | cut -d',' -f1)
        Y=$(echo "$COORDS" | cut -d',' -f2)
        
        # Use same coordinate detection as main menu
        BUTTON=$(get_button_from_coords "$X" "$Y")
        
        # Handle toolbar buttons
        case "$BUTTON" in
            toolbar_light)
                toggle_frontlight
                continue
                ;;
            toolbar_wifi)
                toggle_wifi
                sleep 1
                continue
                ;;
            toolbar_refresh)
                # Refresh the network manager display
                continue
                ;;
            toolbar_reboot)
                reboot_system
                ;;
            toolbar_poweroff)
                # Back button in toolbar - return to settings
                return
                ;;
        esac
        
        # Handle main buttons
        case "$BUTTON" in
            1)
                # Button 1: Current Status - just refresh
                continue
                ;;
            2)
                # Button 2: Enable/Disable WiFi
                toggle_wifi
                sleep 1
                ;;
            3)
                # Button 3: Scan for Networks
                $FBINK -c
                $FBINK -y 15 -pmh "Scanning for networks..."
                $FBINK -y 16 -pm "This may take a few seconds..."
                
                # Trigger scan
                lipc-set-prop com.lab126.wifid scan "" 2>/dev/null
                
                # Wait for scan to complete
                sleep 3
                
                $FBINK -y 18 -pm "Scan complete! Refreshing..."
                sleep 1
                ;;
            4)
                # Button 4: Reconnect
                if [ "$WIFI_ENABLED" = "1" ]; then
                    $FBINK -c
                    $FBINK -y 15 -pmh "Reconnecting..."
                    
                    # Try to reconnect to last network
                    if [ -n "$CURRENT_SSID" ] && [ "$CURRENT_SSID" != "Unknown" ]; then
                        lipc-set-prop com.lab126.cmd ensureConnection "wifi:$CURRENT_SSID" 2>/dev/null
                    fi
                    
                    sleep 2
                else
                    $FBINK -c
                    $FBINK -y 15 -pmh "WiFi is disabled!"
                    $FBINK -y 16 -pm "Enable WiFi first"
                    sleep 2
                fi
                ;;
            5)
                # Button 5: Back to Settings
                return
                ;;
            unknown)
                # Invalid touch
                ;;
        esac
        
        sleep 0.2
    done
}

# Open terminal
open_terminal() {
    # Find kterm
    KTERM="/mnt/us/extensions/kterm/bin/kterm.sh"
    if [ ! -f "$KTERM" ]; then
        $FBINK -c
        $FBINK -y 15 -pmh "kterm not found!"
        sleep 1
        return
    fi
    
    # Kill touch reader first
    killall -9 touch_reader 2>/dev/null
    
    # Signal watchdog NOT to restart (intentional exit for kterm)
    echo "KTERM" > /var/tmp/openreader-state
    
    # Show launching message
    $FBINK -c
    $FBINK -y 12 -pmh "Launching Terminal..."
    sleep 1
    
    # Create launcher script
    cat > /var/tmp/launch-kterm.sh << 'KTERM_EOF'
#!/bin/sh
# Wait for OpenReader to fully exit
sleep 3

# Launch kterm
/mnt/us/extensions/kterm/bin/kterm.sh

# When kterm exits, signal restart
echo "RESTART" > /var/tmp/openreader-state

# Clean up
rm -f /var/tmp/launch-kterm.sh
KTERM_EOF
    
    chmod +x /var/tmp/launch-kterm.sh
    
    # Launch detached
    /var/tmp/launch-kterm.sh </dev/null >/dev/null 2>&1 &
    
    # Exit launcher immediately
    exit 0
}

# Show settings (full settings menu)
show_settings_toolbar() {
    show_settings
}

# Reboot system
reboot_system() {
    $FBINK -c
    $FBINK -y 12 -pmh "⚠️  REBOOTING KINDLE..."
    $FBINK -y 14 -pm "Please wait..."
    sleep 2
    restore_services
    /sbin/reboot
}

# Power off system
poweroff_system() {
    $FBINK -c
    $FBINK -y 12 -pmh "⚠️  POWERING OFF..."
    $FBINK -y 14 -pm "Goodbye!"
    sleep 2
    restore_services
    /sbin/poweroff
}

# Main loop
main() {
    stop_services
    get_screen_size
    
    CURRENT_SELECTION=""
    
    # Trap exit to restore services
    trap 'restore_services; exit 0' INT TERM EXIT
    
    while true; do
        draw_menu "$CURRENT_SELECTION"
        
        # Read touch input (one event at a time)
        COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
        
        if [ -z "$COORDS" ]; then
            continue
        fi
        
        # Parse coordinates
        X=$(echo "$COORDS" | cut -d',' -f1)
        Y=$(echo "$COORDS" | cut -d',' -f2)
        
        # Determine which button
        BUTTON=$(get_button_from_coords "$X" "$Y")
        
        # Handle toolbar buttons (no visual feedback needed)
        case "$BUTTON" in
            toolbar_light)
                toggle_frontlight
                continue
                ;;
            toolbar_wifi)
                toggle_wifi
                continue
                ;;
            toolbar_refresh)
                # Refresh display - just redraw
                CURRENT_SELECTION=""
                continue
                ;;
            toolbar_reboot)
                reboot_system
                ;;
            toolbar_poweroff)
                poweroff_system
                ;;
        esac
        
        # Show selection feedback for main buttons
        CURRENT_SELECTION="$BUTTON"
        draw_menu "$CURRENT_SELECTION"
        sleep 0.3  # Brief visual feedback
        
        # Execute main button actions
        case "$BUTTON" in
            1)
                launch_koreader
                ;;
            2)
                show_system_info
                CURRENT_SELECTION=""
                ;;
            3)
                open_terminal
                ;;
            4)
                # File Browser - placeholder for now
                $FBINK -c
                $FBINK -y 15 -pmh "File Browser"
                $FBINK -y 16 -pm "Coming soon!"
                sleep 2
                CURRENT_SELECTION=""
                ;;
            5)
                show_settings
                CURRENT_SELECTION=""
                ;;
            unknown)
                # Invalid touch, just continue
                CURRENT_SELECTION=""
                ;;
        esac
    done
}

main

