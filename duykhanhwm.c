#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <unistd.h>
#include <stdlib.h>

int main() {
    Display *display = XOpenDisplay(NULL);
    if (!display) return 1;

    Window root = DefaultRootWindow(display);

    // BỔ SUNG: Tự động mở cửa sổ Terminal chứa logo DuyKhanhOS ngay khi khởi động
    if (fork() == 0) {
        execlp("xterm", "xterm", "-geometry", "80x24+100+100", "-e", "/usr/local/bin/duykhanh-fetch", NULL);
        exit(0);
    }

    // Giữ nguyên phím tắt Alt + F1 để mở thêm các cửa sổ Terminal mới sau này
    XGrabKey(display, XKeysymToKeycode(display, XK_F1), Mod1Mask, root, True, GrabModeAsync, GrabModeAsync);

    XEvent ev;
    while (!XNextEvent(display, &ev)) {
        if (ev.type == KeyPress) {
            if (ev.xkey.keycode == XKeysymToKeycode(display, XK_F1) && (ev.xkey.state & Mod1Mask)) {
                if (fork() == 0) {
                    execlp("xterm", "xterm", NULL); // Nhấn Alt + F1 sẽ ra một Terminal trống để gõ lệnh
                    exit(0);
                }
            }
        }
    }

    XCloseDisplay(display);
    return 0;
}
