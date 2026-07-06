#!/bin/bash
set -e

echo "=== 1. Tạo cấu trúc thư mục Live ISO ==="
WORKDIR=$(pwd)
mkdir -p live_boot/chroot
mkdir -p live_boot/image/live
mkdir -p live_boot/image/boot/grub

echo "=== 2. Tải hệ thống nền (Ubuntu/Mint Base) ==="
# Sử dụng debootstrap để dựng hệ thống Linux cơ bản mà không cần giải nén file ISO khác
sudo debootstrap --arch=amd64 noble live_boot/chroot http://ubuntu.com

echo "=== 3. Cấu hình hệ thống và cài đặt môi trường đồ họa ==="
# Lệnh chroot giúp chui vào bên trong OS mới để cài đặt Xorg và các công cụ cần thiết
sudo chroot live_boot/chroot apt-get update
sudo chroot live_boot/chroot apt-get install -y --no-install-recommends \
    xserver-xorg-core xserver-xorg-input-libinput xinit libx11-6

echo "=== 4. Biên dịch DuyKhanhWM và tích hợp vào hệ thống ==="
if [ -f "duykhanhwm.c" ]; then
    gcc duykhanhwm.c -o duykhanhwm -lX11
    sudo cp duykhanhwm live_boot/chroot/usr/local/bin/duykhanhwm
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanhwm
    
    # Cấu hình để khi khởi động, hệ thống tự gọi DuyKhanhWM
    echo "exec duykhanhwm" | sudo tee live_boot/chroot/root/.xinitrc
else
    echo "Cảnh báo: Không tìm thấy file duykhanhwm.c!"
fi

echo "=== 5. Đưa script duykhanh-fetch vào hệ thống ==="
if [ -f "duykhanh-fetch.sh" ]; then
    sudo cp duykhanh-fetch.sh live_boot/chroot/usr/local/bin/duykhanh-fetch
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanh-fetch
fi

echo "=== 6. Nén hệ thống thành file filesystem.squashfs ==="
sudo mksquashfs live_boot/chroot live_boot/image/live/filesystem.squashfs -noappend -e boot

echo "=== 7. Cấu hình Menu Boot (GRUB) ==="
if [ -f "grub.cfg" ]; then
    cp grub.cfg live_boot/image/boot/grub/grub.cfg
else
    # Nếu chưa có file grub.cfg, tự tạo một file mặc định
    cat << EOF > live_boot/image/boot/grub/grub.cfg
set default=0
set timeout=5

menuentry "DuyKhanhOS Live (Mint Base)" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF
fi

# Sao chép nhân Linux (Kernel) và Ramdisk vào thư mục boot của ISO
sudo cp live_boot/chroot/boot/vmlinuz-* live_boot/image/live/vmlinuz || true
sudo cp live_boot/chroot/boot/initrd.img-* live_boot/image/live/initrd.img || true

echo "=== 8. Đóng gói thành file ISO hoàn chỉnh ==="
grub-mkrescue -o duykhanh-os.iso live_boot/image

echo "=== THÀNH CÔNG: Đã tạo xong file duykhanh-os.iso ==="
