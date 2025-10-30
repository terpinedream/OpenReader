#!/bin/sh
# Touch Calibration Script - EXACT UI COPY
# Collects corner coordinates for main buttons + general coords for toolbar
# Auto-exits after all inputs collected, saves to USB

SCRIPT_DIR="$(dirname "$0")"
FBINK="/mnt/us/koreader/fbink"
TOUCH_READER="$SCRIPT_DIR/touch_reader"
LOGFILE_TMP="/tmp/touch-calibration-results.txt"
LOGFILE_USB="/mnt/us/touch-calibration-results.txt"
KEEPER_PID=""

[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Ensure touch_reader exists
if [ ! -f "$TOUCH_READER" ]; then
    echo "ERROR: touch_reader not found at $TOUCH_READER" > "$LOGFILE_USB"
    exit 1
fi

# ═══════════════════════════════════════════════════
# FRAMEWORK KEEPER - Runs in background
# ═══════════════════════════════════════════════════
framework_keeper() {
    while true; do
        killall -STOP cvm 2>/dev/null
        killall -STOP lipc-wait-event 2>/dev/null
        killall -STOP webreader 2>/dev/null
        killall -STOP kfxreader 2>/dev/null
        killall -STOP kfxview 2>/dev/null
        killall -STOP mesquite 2>/dev/null
        killall -STOP browserd 2>/dev/null
        killall -STOP stored 2>/dev/null
        killall -STOP todo 2>/dev/null
        killall -STOP tmd 2>/dev/null
        killall -STOP rcm 2>/dev/null
        killall -STOP archive 2>/dev/null
        killall -STOP scanner 2>/dev/null
        killall -STOP otav3 2>/dev/null
        killall -STOP otaupd 2>/dev/null
        killall -STOP volumd 2>/dev/null
        sleep 1
    done
}

stop_all_services() {
    lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
    
    killall -STOP cvm 2>/dev/null
    killall -STOP lipc-wait-event 2>/dev/null
    killall -STOP webreader 2>/dev/null
    killall -STOP kfxreader 2>/dev/null
    killall -STOP kfxview 2>/dev/null
    killall -STOP mesquite 2>/dev/null
    killall -STOP browserd 2>/dev/null
    killall -STOP stored 2>/dev/null
    killall -STOP todo 2>/dev/null
    killall -STOP tmd 2>/dev/null
    killall -STOP rcm 2>/dev/null
    killall -STOP archive 2>/dev/null
    killall -STOP scanner 2>/dev/null
    killall -STOP otav3 2>/dev/null
    killall -STOP otaupd 2>/dev/null
    killall -STOP volumd 2>/dev/null
    
    echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
    sleep 1
    
    framework_keeper &
    KEEPER_PID=$!
}

# ═══════════════════════════════════════════════════
# DRAW EXACT UI (from touch-launcher.sh)
# ═══════════════════════════════════════════════════
draw_ui() {
    HIGHLIGHT=$1
    
    $FBINK -c
    
    # Banner
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
    $FBINK -y 19 -pm "       🧪 CALIBRATION MODE 🧪"
    
    # Button 1
    if [ "$HIGHLIGHT" = "1" ]; then
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
    
    # Button 2
    if [ "$HIGHLIGHT" = "2" ]; then
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
    
    # Button 3
    if [ "$HIGHLIGHT" = "3" ]; then
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
    
    # Button 4
    if [ "$HIGHLIGHT" = "4" ]; then
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
    
    # Button 5
    if [ "$HIGHLIGHT" = "5" ]; then
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
    
    # Toolbar
    if [ "$HIGHLIGHT" = "toolbar" ]; then
        $FBINK -y 51 -pmh "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        $FBINK -y 52 -pmh "┌───────┬───────┬───────┬───────┬──────┐"
        $FBINK -y 53 -pmh "│[LIGHT]│[WIFI ]│[REFRH]│[BOOT ]│[OFF ]│"
        $FBINK -y 54 -pmh "└───────┴───────┴───────┴───────┴──────┘"
    else
        $FBINK -y 51 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        $FBINK -y 52 -pm "┌───────┬───────┬───────┬───────┬──────┐"
        $FBINK -y 53 -pm "│[LIGHT]│[WIFI ]│[REFRH]│[BOOT ]│[OFF ]│"
        $FBINK -y 54 -pm "└───────┴───────┴───────┴───────┴──────┘"
    fi
}

# ═══════════════════════════════════════════════════
# MAIN CALIBRATION ROUTINE
# ═══════════════════════════════════════════════════
main() {
    # Initialize log
    echo "═══════════════════════════════════════════════════" > "$LOGFILE_TMP"
    echo "  OPENREADER LAUNCHER - TOUCH CALIBRATION" >> "$LOGFILE_TMP"
    echo "═══════════════════════════════════════════════════" >> "$LOGFILE_TMP"
    echo "" >> "$LOGFILE_TMP"
    echo "Generated: $(date)" >> "$LOGFILE_TMP"
    echo "Device: /dev/input/event1" >> "$LOGFILE_TMP"
    echo "" >> "$LOGFILE_TMP"
    
    cp "$LOGFILE_TMP" "$LOGFILE_USB" 2>/dev/null
    
    stop_all_services
    
    # Calibrate main buttons (4 corners each)
    for BTN in 1 2 3 4 5; do
        case $BTN in
            1) BTN_NAME="[BOOK] KOREADER" ;;
            2) BTN_NAME="[INFO] SYSTEM INFO" ;;
            3) BTN_NAME="[TERM] TERMINAL" ;;
            4) BTN_NAME="[FILE] FILE BROWSER" ;;
            5) BTN_NAME="[GEAR] SETTINGS" ;;
        esac
        
        echo "" >> "$LOGFILE_TMP"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE_TMP"
        echo "Button $BTN: $BTN_NAME" >> "$LOGFILE_TMP"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE_TMP"
        echo "Touch 4 corners: TOP-LEFT, TOP-RIGHT, BOTTOM-LEFT, BOTTOM-RIGHT" >> "$LOGFILE_TMP"
        echo "" >> "$LOGFILE_TMP"
        
        for CORNER in 1 2 3 4; do
            case $CORNER in
                1) CORNER_NAME="Top-Left" ;;
                2) CORNER_NAME="Top-Right" ;;
                3) CORNER_NAME="Bottom-Left" ;;
                4) CORNER_NAME="Bottom-Right" ;;
            esac
            
            draw_ui "$BTN"
            $FBINK -y 56 -pmh "Touch $CORNER_NAME corner of Button $BTN"
            
            COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
            if [ -n "$COORDS" ]; then
                X=$(echo "$COORDS" | cut -d',' -f1)
                Y=$(echo "$COORDS" | cut -d',' -f2)
                echo "  $CORNER_NAME: X=$X, Y=$Y" >> "$LOGFILE_TMP"
                cp "$LOGFILE_TMP" "$LOGFILE_USB" 2>/dev/null
                sleep 0.3
            fi
        done
    done
    
    # Calibrate toolbar (3 touches per button)
    echo "" >> "$LOGFILE_TMP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE_TMP"
    echo "TOOLBAR CALIBRATION" >> "$LOGFILE_TMP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE_TMP"
    echo "Touch each toolbar button 3 times" >> "$LOGFILE_TMP"
    echo "" >> "$LOGFILE_TMP"
    
    for TB_BTN in 1 2 3 4 5; do
        case $TB_BTN in
            1) TB_NAME="[LIGHT]" ;;
            2) TB_NAME="[WIFI]" ;;
            3) TB_NAME="[REFRH]" ;;
            4) TB_NAME="[BOOT]" ;;
            5) TB_NAME="[OFF]" ;;
        esac
        
        echo "" >> "$LOGFILE_TMP"
        echo "Toolbar Button $TB_BTN: $TB_NAME" >> "$LOGFILE_TMP"
        
        for TOUCH in 1 2 3; do
            draw_ui "toolbar"
            $FBINK -y 56 -pmh "Touch $TB_NAME button ($TOUCH/3)"
            
            COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
            if [ -n "$COORDS" ]; then
                X=$(echo "$COORDS" | cut -d',' -f1)
                Y=$(echo "$COORDS" | cut -d',' -f2)
                echo "  Touch $TOUCH: X=$X, Y=$Y" >> "$LOGFILE_TMP"
                cp "$LOGFILE_TMP" "$LOGFILE_USB" 2>/dev/null
                sleep 0.3
            fi
        done
    done
    
    # Analysis section
    echo "" >> "$LOGFILE_TMP"
    echo "═══════════════════════════════════════════════════" >> "$LOGFILE_TMP"
    echo "  CALIBRATION COMPLETE!" >> "$LOGFILE_TMP"
    echo "═══════════════════════════════════════════════════" >> "$LOGFILE_TMP"
    echo "" >> "$LOGFILE_TMP"
    echo "Results saved to:" >> "$LOGFILE_TMP"
    echo "  • /tmp/touch-calibration-results.txt" >> "$LOGFILE_TMP"
    echo "  • /mnt/us/touch-calibration-results.txt (USB)" >> "$LOGFILE_TMP"
    echo "" >> "$LOGFILE_TMP"
    echo "Next steps:" >> "$LOGFILE_TMP"
    echo "  1. Plug Kindle into computer" >> "$LOGFILE_TMP"
    echo "  2. Open touch-calibration-results.txt" >> "$LOGFILE_TMP"
    echo "  3. Calculate button boundaries from corner coordinates" >> "$LOGFILE_TMP"
    echo "  4. Calculate toolbar X-axis divisions" >> "$LOGFILE_TMP"
    echo "  5. Update touch-launcher.sh with new thresholds" >> "$LOGFILE_TMP"
    
    cp "$LOGFILE_TMP" "$LOGFILE_USB" 2>/dev/null
    
    # Show completion
    $FBINK -c
    $FBINK -y 12 -pmh "✅ CALIBRATION COMPLETE!"
    $FBINK -y 14 -pm "Results saved to USB storage:"
    $FBINK -y 15 -pmh "touch-calibration-results.txt"
    $FBINK -y 17 -pm "Plug Kindle into computer to view"
    $FBINK -y 19 -pm "Cleaning up in 3 seconds..."
    
    sleep 3
    
    # Cleanup
    if [ -n "$KEEPER_PID" ]; then
        kill $KEEPER_PID 2>/dev/null
    fi
    
    killall -TERM touch_reader 2>/dev/null
    lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
    
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
    
    echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
}

main
exit 0




