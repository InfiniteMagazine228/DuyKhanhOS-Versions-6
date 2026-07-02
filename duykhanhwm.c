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

    // Định nghĩa bảng màu theo phong cách Kali Linux Dark Theme
    unsigned long kali_neon_blue = 0x00a3ff; // Màu xanh neon thương hiệu
    unsigned long kali_dark_bg   = 0x0f141c; // Nền tối sâu của hệ thống

    // 1. Kết nối tới X Server X11
    if (!(dpy = XOpenDisplay(0x0))) {
        fprintf(stderr, "DuyKhanhOS Error: Không thể kết nối tới X Server!\n");
        return 1;
    }

    root = DefaultRootWindow(dpy);

    // Đổi màu nền màn hình chính (Root Window) sang màu tối Kali
    XSetWindowBackground(dpy, root, kali_dark_bg);
    XClearWindow(dpy, root);

    // 2. Định nghĩa các tổ hợp phím và chuột điều khiển
    // Giữ phím Alt (Mod1Mask) + Chuột trái để di chuyển cửa sổ ứng dụng
    XGrabButton(dpy, 1, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);
    // Giữ phím Alt (Mod1Mask) + Chuột phải để thay đổi kích thước (Resize)
    XGrabButton(dpy, 3, Mod1Mask, root, True, ButtonPressMask, GrabModeAsync, GrabModeAsync, None, None);

    // Gán phím tắt hệ thống: Alt + Enter để tự động mở Terminal
    XGrabKey(dpy, XKeysymToKeycode(dpy, XK_Return), Mod1Mask, root, True, GrabModeAsync, GrabModeAsync);

    printf("=== DuyKhanhOS Window Manager v6 (Kali-Style) đang khởi chạy... ===\n");

    // 3. Vòng lặp lắng nghe sự kiện từ hệ thống (Event Loop)
    while (!XNextEvent(dpy, &ev)) {
        // Sự kiện người dùng nhấn chuột vào một cửa sổ con
        if (ev.type == ButtonPress && ev.xbutton.subwindow != None) {
            XGetWindowAttributes(dpy, ev.xbutton.subwindow, &attr);
            start = ev.xbutton;
            
            // Vẽ viền dày màu xanh Neon xung quanh cửa sổ đang được chọn (Active)
            XSetWindowBorderWidth(dpy, ev.xbutton.subwindow, 3);
            XSetWindowBorder(dpy, ev.xbutton.subwindow, kali_neon_blue);
        } 
        // Sự kiện kéo thả chuột để di chuyển hoặc kéo giãn cửa sổ
        else if (ev.type == MotionNotify && start.subwindow != None) {
            int xdiff = ev.xbutton.x_root - start.x_root;
            int ydiff = ev.xbutton.y_root - start.y_root;

            XMoveResizeWindow(dpy, start.subwindow,
                attr.x + (start.button == 1 ? xdiff : 0),
                attr.y + (start.button == 1 ? ydiff : 0),
                MAX(100, attr.width + (start.button == 3 ? xdiff : 0)),
                MAX(100, attr.height + (start.button == 3 ? ydiff : 0)));
        }
        // Sự kiện kích hoạt phím tắt từ bàn phím
        else if (ev.type == KeyPress) {
            // Khi nhấn Alt + Enter -> Ưu tiên gọi Alacritty, nếu lỗi gọi XFCE Terminal
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
