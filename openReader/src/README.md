# Touch Reader Binary

Custom C program to read raw touch events from Kindle's touchscreen.

## Building

### On Kindle (using kterm)

```bash
cd /mnt/us/extensions/kindlelauncher/src
make
cp touch_reader ../bin/
```

### Cross-Compile (Linux)

Install ARM toolchain:
```bash
sudo apt-get install gcc-arm-linux-gnueabi
```

Build:
```bash
make CC=arm-linux-gnueabi-gcc
```

Copy to Kindle via USB, then:
```bash
chmod +x touch_reader
cp touch_reader ../bin/
```

## Usage

```bash
./touch_reader /dev/input/event1
```

Outputs:
```
X=379 Y=512
```

Press Ctrl+C to exit.

## Technical Details

- Reads from Linux input event device (`/dev/input/event1`)
- Filters for absolute position events (EV_ABS)
- Reports ABS_MT_POSITION_X and ABS_MT_POSITION_Y
- Outputs coordinates on touch release (BTN_TOUCH up)
- Non-blocking I/O with signal handling for clean exit

## Device Paths

Most Kindles use `/dev/input/event1` for touchscreen. Verify with:
```bash
cat /proc/bus/input/devices
```

Look for device with `cyttsp` or touch in the name.
