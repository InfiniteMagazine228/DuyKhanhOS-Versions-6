#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))

int main() {
    Display * dpy;
    Window root;
    XWindowAttributes attr;
    XButtonEvent start;
    XEvent ev;

    // 1. Kết nối tới X Server
    if (!(dpy = XOpenDisplay(0x0))) {
        fprintf(stderr, "Không thể kết nối tới X Server!\n");
        return 1;
    }

    root = DefaultRootWindow(dpy);

    // 2. Định nghĩa phím tắt điều khiển cửa sổ (Alt + Chuột)
    // Giữ phím Alt (Mod1Mask) + Chuột trái để di chuyển cửa sổ
    XGrabButton(dpy, 1, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);
    // Giữ phím Alt (Mod1Mask) + Chuột phải để thay đổi kích thước
    XGrabButton(dpy, 3, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);

    printf("DuyKhanhOS Window Manager v6 đang chạy...\n");

    // 3. Vòng lặp lắng nghe sự kiện từ X11 (Event Loop)
    while (!XNextEvent(dpy, &ev)) {
        if (ev.type == ButtonPress && ev.xbutton.subwindow != None) {
            // Lưu lại vị trí chuột ban đầu khi nhấn xuống
            XGetWindowAttributes(dpy, ev.xbutton.subwindow, &attr);
            start = ev.xbutton;
        } 
        else if (ev.type == MotionNotify && start.subwindow != None) {
            // Tính toán khoảng cách di chuyển của chuột
            int xdiff = ev.xbutton.x_root - start.x_root;
            int ydiff = ev.xbutton.y_root - start.y_root;

            // Xử lý di chuyển hoặc thay đổi kích thước cửa sổ
            XMoveResizeWindow(dpy, start.subwindow,
                attr.x + (start.button == 1 ? xdiff : 0),
                attr.y + (start.button == 1 ? ydiff : 0),
                MAX(1, attr.width + (start.button == 3 ? xdiff : 0)),
                MAX(1, attr.height + (start.button == 3 ? ydiff : 0)));
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
