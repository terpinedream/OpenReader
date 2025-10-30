/*
 * Kindle Touch Reader
 * Reads touch input from /dev/input/event* and outputs coordinates
 * Cross-compile for ARM: arm-linux-gnueabihf-gcc
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/input.h>
#include <errno.h>
#include <signal.h>

#define MAX_DEVICES 10

static volatile int running = 1;

void signal_handler(int sig) {
    running = 0;
}

/* Find the touch device */
int find_touch_device(char *device_path, size_t path_size) {
    int i;
    char path[256];
    char name[256];
    int fd;
    
    /* Try common touch device paths */
    const char *common_paths[] = {
        "/dev/input/event0",
        "/dev/input/event1",
        "/dev/input/event2",
        NULL
    };
    
    for (i = 0; common_paths[i] != NULL; i++) {
        fd = open(common_paths[i], O_RDONLY | O_NONBLOCK);
        if (fd < 0) {
            continue;
        }
        
        /* Try to get device name */
        if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) >= 0) {
            /* Look for touch-related keywords */
            if (strstr(name, "touch") != NULL || 
                strstr(name, "Touch") != NULL ||
                strstr(name, "touchscreen") != NULL ||
                strstr(name, "elan") != NULL) {
                snprintf(device_path, path_size, "%s", common_paths[i]);
                close(fd);
                fprintf(stderr, "Found touch device: %s (%s)\n", device_path, name);
                return 0;
            }
        }
        close(fd);
    }
    
    /* Default to event1 if nothing found */
    snprintf(device_path, path_size, "/dev/input/event1");
    fprintf(stderr, "Using default: %s\n", device_path);
    return 0;
}

/* Main touch reading loop */
int read_touch_events(const char *device_path) {
    int fd;
    struct input_event ev;
    int touch_x = -1;
    int touch_y = -1;
    int touch_active = 0;
    
    fd = open(device_path, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "Error: Cannot open %s: %s\n", device_path, strerror(errno));
        return 1;
    }
    
    fprintf(stderr, "Listening for touch events on %s...\n", device_path);
    fprintf(stderr, "(Press Ctrl+C to exit)\n");
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    while (running) {
        ssize_t bytes = read(fd, &ev, sizeof(ev));
        
        if (bytes < 0) {
            if (errno == EINTR) {
                continue;
            }
            fprintf(stderr, "Error reading: %s\n", strerror(errno));
            break;
        }
        
        if (bytes < (ssize_t)sizeof(ev)) {
            continue;
        }
        
        /* Process touch events */
        if (ev.type == EV_ABS) {
            if (ev.code == ABS_X || ev.code == ABS_MT_POSITION_X) {
                touch_x = ev.value;
            } else if (ev.code == ABS_Y || ev.code == ABS_MT_POSITION_Y) {
                touch_y = ev.value;
            }
        } else if (ev.type == EV_KEY) {
            if (ev.code == BTN_TOUCH) {
                touch_active = ev.value;
            }
        } else if (ev.type == EV_SYN && ev.code == SYN_REPORT) {
            /* Complete touch event */
            if (touch_active && touch_x >= 0 && touch_y >= 0) {
                /* Output format: x,y */
                printf("%d,%d\n", touch_x, touch_y);
                fflush(stdout);
                /* Exit after first touch for shell script compatibility */
                close(fd);
                return 0;
            } else if (!touch_active && touch_x >= 0 && touch_y >= 0) {
                /* Touch released - output final position */
                printf("%d,%d\n", touch_x, touch_y);
                fflush(stdout);
                close(fd);
                return 0;
            }
        }
    }
    
    close(fd);
    return 0;
}

int main(int argc, char *argv[]) {
    char device_path[256];
    
    if (argc > 1) {
        /* Device path provided as argument */
        snprintf(device_path, sizeof(device_path), "%s", argv[1]);
    } else {
        /* Auto-detect touch device */
        if (find_touch_device(device_path, sizeof(device_path)) != 0) {
            fprintf(stderr, "Failed to find touch device\n");
            return 1;
        }
    }
    
    return read_touch_events(device_path);
}

