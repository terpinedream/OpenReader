#!/bin/sh
# Slider Calibration Test Script
# Collects precise start/end coordinates for the frontlight slider

SCRIPT_DIR="$(dirname "$0")"
FBINK="/mnt/us/koreader/fbink"
TOUCH_READER="$SCRIPT_DIR/touch_reader"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Check if touch_reader exists
if [ ! -f "$TOUCH_READER" ]; then
    $FBINK -c
    $FBINK -y 10 -pmh "Error: touch_reader not found!"
    sleep 3
    exit 1
fi

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

# Stop Kindle services (prevent auto-restart)
stop_services() {
    lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
    killall -STOP cvm 2>/dev/null
    killall -STOP lipc-wait-event 2>/dev/null
    killall -STOP webreader 2>/dev/null
    killall -STOP kfxreader 2>/dev/null
    echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
    sleep 0.5
}

# Restore services
restore_services() {
    killall -TERM touch_reader 2>/dev/null
    lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
    killall -CONT cvm 2>/dev/null
    killall -CONT lipc-wait-event 2>/dev/null
    killall -CONT webreader 2>/dev/null
    killall -CONT kfxreader 2>/dev/null
    echo 1 > /proc/eink_fb/update_display 2>/dev/null || true
}

# Keep framework suspended
framework_keeper() {
    while true; do
        killall -STOP cvm 2>/dev/null
        killall -STOP lipc-wait-event 2>/dev/null
        sleep 1
    done
}

# Draw the calibration UI (exact copy of settings slider)
draw_calibration_ui() {
    INSTRUCTION=$1
    
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
    $FBINK -y 19 -pmh "        SLIDER CALIBRATION TEST"
    
    # Slider button (with empty slider for now)
    $FBINK -y 21 -pm "┌──────────────────────────────────────┐"
    $FBINK -y 22 -pm "│                                      │"
    $FBINK -y 23 -pm "│  [LIGHT] [░░░░░░░░░░░░░░░░░░░░░░░░]  │"
    $FBINK -y 24 -pm "└──────────────────────────────────────┘"
    
    # Instructions
    $FBINK -y 27 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 28 -pmh "$INSTRUCTION"
    $FBINK -y 29 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    $FBINK -y 31 -pm "This will help calibrate the exact slider"
    $FBINK -y 32 -pm "boundaries for precise brightness control."
    $FBINK -y 34 -pm "Touch the slider at the specified position..."
}

# Main calibration routine
main() {
    stop_services
    
    # Start framework keeper in background
    framework_keeper &
    KEEPER_PID=$!
    
    # Trap exit
    trap "kill $KEEPER_PID 2>/dev/null; restore_services; exit 0" INT TERM EXIT
    
    # Collect START point
    draw_calibration_ui "STEP 1/2: Touch LEFT edge of slider"
    START_COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
    START_X=$(echo "$START_COORDS" | cut -d',' -f1)
    START_Y=$(echo "$START_COORDS" | cut -d',' -f2)
    
    sleep 0.5
    
    # Collect END point
    draw_calibration_ui "STEP 2/2: Touch RIGHT edge of slider"
    END_COORDS=$("$TOUCH_READER" /dev/input/event1 2>/dev/null)
    END_X=$(echo "$END_COORDS" | cut -d',' -f1)
    END_Y=$(echo "$END_COORDS" | cut -d',' -f2)
    
    # Calculate slider width
    SLIDER_WIDTH=$((END_X - START_X))
    
    # Display results
    $FBINK -c
    $FBINK -y 10 -pmh "═══════════════════════════════════════"
    $FBINK -y 11 -pmh "   SLIDER CALIBRATION RESULTS"
    $FBINK -y 12 -pmh "═══════════════════════════════════════"
    $FBINK -y 14 -pm "Start Point (LEFT edge):"
    $FBINK -y 15 -pm "  X: $START_X, Y: $START_Y"
    $FBINK -y 17 -pm "End Point (RIGHT edge):"
    $FBINK -y 18 -pm "  X: $END_X, Y: $END_Y"
    $FBINK -y 20 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 21 -pmh "Slider Width: $SLIDER_WIDTH pixels"
    $FBINK -y 22 -pm "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $FBINK -y 24 -pm "Recommended code update:"
    $FBINK -y 25 -pm "  X_OFFSET=\$((X - $START_X))"
    $FBINK -y 26 -pm "  NEW_BRIGHT=\$((X_OFFSET * 1200 / $SLIDER_WIDTH))"
    $FBINK -y 28 -pm "Saving results to USB..."
    
    # Save to file
    RESULT_FILE="/mnt/us/slider-calibration-results.txt"
    cat > "$RESULT_FILE" << EOF
═══════════════════════════════════════════════════
  SLIDER CALIBRATION RESULTS
═══════════════════════════════════════════════════

Generated: $(date)
Device: /dev/input/event1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CALIBRATION DATA:

Start Point (LEFT edge of slider):
  X: $START_X
  Y: $START_Y

End Point (RIGHT edge of slider):
  X: $END_X
  Y: $END_Y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CALCULATED VALUES:

Slider Width: $SLIDER_WIDTH pixels
Y Position: $START_Y (consistent)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDED CODE UPDATE:

In touch-launcher.sh, update the slider handler:

# Calculate brightness from X position
X_OFFSET=\$((X - $START_X))
if [ \$X_OFFSET -lt 0 ]; then X_OFFSET=0; fi
if [ \$X_OFFSET -gt $SLIDER_WIDTH ]; then X_OFFSET=$SLIDER_WIDTH; fi

# Calculate brightness (0-1200)
NEW_BRIGHT=\$((X_OFFSET * 1200 / $SLIDER_WIDTH))
if [ \$NEW_BRIGHT -lt 0 ]; then NEW_BRIGHT=0; fi
if [ \$NEW_BRIGHT -gt 1200 ]; then NEW_BRIGHT=1200; fi

# Set new brightness
echo "\$NEW_BRIGHT" > "\$FL_PATH" 2>/dev/null

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ANALYSIS:

Precision: $(((1200 * 100) / SLIDER_WIDTH))% accuracy
  ($SLIDER_WIDTH pixels / 1200 levels = $((SLIDER_WIDTH * 1000 / 1200 / 10)).$((SLIDER_WIDTH * 1000 / 1200 % 10)) pixels/level)

This gives you precise control over the full 0-1200
brightness range using the exact slider dimensions.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
1. Copy values above into touch-launcher.sh
2. Test slider for smooth brightness control
3. Enjoy precise frontlight adjustment!

EOF
    
    $FBINK -y 30 -pmh "✓ Saved to: $RESULT_FILE"
    $FBINK -y 32 -pm "Touch anywhere to exit..."
    
    # Wait for final touch
    "$TOUCH_READER" /dev/input/event1 2>/dev/null >/dev/null
    
    # Cleanup
    kill $KEEPER_PID 2>/dev/null
    restore_services
}

main




