#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))

int main() {
    Display *dpy;
    Window root;
    XWindowAttributes attr;
    XButtonEvent start;
    XEvent ev;

    unsigned long kali_neon_blue = 0x00a3ff; 
    unsigned long kali_dark_bg   = 0x0f141c; 

    if (!(dpy = XOpenDisplay(0x0))) {
        fprintf(stderr, "DuyKhanhOS Error: Khong the ket noi toi X Server!\n");
        return 1;
    }

    root = DefaultRootWindow(dpy);
    XSetWindowBackground(dpy, root, kali_dark_bg);
    XClearWindow(dpy, root);

    XGrabButton(dpy, 1, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);
    XGrabButton(dpy, 3, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);
    XGrabKey(dpy, XKeysymToKeycode(dpy, XK_Return), Mod1Mask, root, True, GrabModeAsync, GrabModeAsync);

    printf("=== DuyKhanhOS Window Manager v6 (Kali-Style) dang chay... ===\n");

    while (!XNextEvent(dpy, &ev)) {
        if (ev.type == ButtonPress && ev.xbutton.subwindow != None) {
            XGetWindowAttributes(dpy, ev.xbutton.subwindow, &attr);
            start = ev.xbutton;
            XSetWindowBorderWidth(dpy, ev.xbutton.subwindow, 3);
            XSetWindowBorder(dpy, ev.xbutton.subwindow, kali_neon_blue);
        } 
        else if (ev.type == MotionNotify && start.subwindow != None) {
            int xdiff = ev.xbutton.x_root - start.x_root;
            int ydiff = ev.xbutton.y_root - start.y_root;

            XMoveResizeWindow(dpy, start.subwindow,
                attr.x + (start.button == 1 ? xdiff : 0),
                attr.y + (start.button == 1 ? ydiff : 0),
                MAX(100, attr.width + (start.button == 3 ? xdiff : 0)),
                MAX(100, attr.height + (start.button == 3 ? ydiff : 0)));
        }
        else if (ev.type == KeyPress) {
            if (ev.xkey.keycode == XKeysymToKeycode(dpy, XK_Return)) {
                if (system("alacritty &") != 0) {
                    system("xfce4-terminal &");
                }
            }
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
