#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <unistd.h>
#include <stdlib.h>

int main() {
    Display *display = XOpenDisplay(NULL);
    if (!display) return 1;

    Window root = DefaultRootWindow(display);

    // Gán phím tắt Alt + F1 để mở terminal chạy script fetch của bạn
    XGrabKey(display, XKeysymToKeycode(display, XK_F1), Mod1Mask, root, True, GrabModeAsync, GrabModeAsync);

    XEvent ev;
    while (!XNextEvent(display, &ev)) {
        if (ev.type == KeyPress) {
            if (ev.xkey.keycode == XKeysymToKeycode(display, XK_F1) && (ev.xkey.state & Mod1Mask)) {
                if (fork() == 0) {
                    // Mở cửa sổ terminal chạy script fetch thông tin DuyKhanhOS
                    execlp("xterm", "xterm", "-e", "/usr/local/bin/duykhanh-fetch", NULL);
                    exit(0);
                }
            }
        }
    }

    XCloseDisplay(display);
    return 0;
}
