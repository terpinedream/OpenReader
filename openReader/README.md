# OpenReader - Touch-Based Kindle Launcher

A minimal, touch-enabled launcher for Kindle e-readers that replaces the stock Amazon UI with a clean interface for launching KOReader, terminal, and other apps.

## Features

- Clean touch-based UI optimized for e-ink displays
- Launch KOReader, terminal, and system tools
- Settings menu with frontlight slider and WiFi control
- Network manager for WiFi connections
- Optional "Amazon-Free Boot" mode to launch at startup
- Boot-time framework suspension using SIGSTOP (prevents service restarts)

## Requirements

- Jailbroken Kindle (any modern model with touchscreen)
- KUAL (Kindle Unified Application Launcher)
- fbink (included with KOReader, or install standalone)
- KOReader installed at `/mnt/us/koreader/` (optional but recommended)
- kterm installed at `/mnt/us/extensions/kterm/` (optional)

## Installation

1. Extract the `openReader` folder to `/mnt/us/extensions/`
2. Launch from KUAL menu: "OpenReader Launcher" > "Launch OpenReader"

The touch reader binary is precompiled and ready to use. If it doesn't work on your Kindle model, recompile it:
```bash
cd /mnt/us/extensions/openReader/src
make
cp touch_reader ../bin/
```

## Amazon-Free Boot (Optional)

Replace the Kindle's default boot UI with OpenReader:

1. From KUAL: "Install Amazon-Free Boot"
2. Reboot

The Kindle will now boot directly to OpenReader instead of the stock UI.

**Note:** Without Amazon-Free Boot installed, you can still launch OpenReader from KUAL, but the Amazon framework will continue running in the background (suspended) and can sometimes interfere with UI elements/touch controls.

### Emergency Recovery

If something goes wrong:

**Method 1: USB Override**
- Connect Kindle via USB
- Create empty file: `BOOT_KINDLEOS` in root directory
- Reboot

**Method 2: SSH/Terminal**
- Connect via SSH or open kterm
- Run: `rm /etc/upstart/openreader-boot.conf`
- Reboot

**Method 3: Settings Menu**
- From OpenReader Settings: "Exit to Kindle OS"

## Touch Calibration

If touch detection is inaccurate:

1. From KUAL: "Calibrate Touch Controls"
2. Touch each button's 4 corners as prompted
3. From KUAL: "Calibrate Slider"
4. Touch slider start and end points

Calibration coordinates are automatically applied.

## File Structure

```
openReader/
├── bin/
│   ├── touch-launcher.sh          # Main launcher
│   ├── boot-replacement.sh        # Boot-time initialization
│   ├── touch_reader               # Touch input binary
│   ├── install-amazon-free-boot.sh
│   ├── uninstall-amazon-free-boot.sh
│   ├── test-touch-calibration.sh
│   └── test-slider-calibration.sh
├── src/
│   ├── touch_reader.c             # Touch input source
│   ├── Makefile
│   └── README.md
├── openreader-boot.conf           # Upstart configuration
├── menu.json                      # KUAL menu
├── config.xml                     # KUAL metadata
└── README.md
```

## How It Works

### Touch Input
- Custom C binary reads raw events from `/dev/input/event1`
- Shell script maps coordinates to UI buttons
- Calibration adjusts thresholds for different models

### Framework Management
- Uses SIGSTOP to suspend Amazon services (prevents auto-restart)
- Framework remains in memory but frozen
- Can be resumed to return to stock UI

### Boot Sequence (Amazon-Free Mode)
1. Upstart config triggers before framework starts
2. `boot-replacement.sh` suspends framework processes
3. Framework keeper maintains suspension
4. Watchdog auto-restarts launcher if it crashes
5. State management tracks current app (RUNNING/KOREADER/KTERM/EXIT)

### KOReader Integration
- Pauses framework keeper while KOReader runs
- Monitors KOReader process for exit
- Automatically returns to OpenReader when closed
- Stubs system commands to prevent hangs

## Troubleshooting

**Touch not working:**
- Check that `touch_reader` binary exists in `bin/` directory
- Run calibration from KUAL menu
- Verify device path: `cat /proc/bus/input/devices` (look for touchscreen)

**KOReader doesn't launch:**
- Verify KOReader installed at `/mnt/us/koreader/`
- Check KOReader version (requires recent build)

**Can't return to stock UI:**
- Open Settings > "Exit to Kindle OS"
- Or create `BOOT_KINDLEOS` file via USB

**Boot loops:**
- Automatic safety: >3 boots in 60s falls back to stock UI
- Manual: Delete `/etc/upstart/openreader-boot.conf`

## Credits

- Built on fbink for e-ink rendering
- Boot system inspired by KOReader's framework management
- Touch input handling adapted from various Kindle projects

## License

MIT License - See LICENSE file for full text
