#!/bin/bash
set -e

echo "=== 1. Tạo cấu trúc thư mục Live ISO ==="
WORKDIR=$(pwd)
mkdir -p live_boot/chroot
mkdir -p live_boot/image/live
mkdir -p live_boot/image/boot/grub

echo "=== 2. Tải hệ thống nền (Ubuntu/Mint Base) ==="
# Tải hệ thống cơ sở sạch
sudo debootstrap --arch=amd64 noble live_boot/chroot http://ubuntu.com

echo "=== 3. Cấu hình hệ thống và cài đặt Nhân (Kernel) + Đồ họa ==="
# Cập nhật kho ứng dụng bên trong chroot
sudo chroot live_boot/chroot apt-get update

# BẮT BUỘC: Cài đặt nhân Linux và live-boot để sửa lỗi "vmlinuz not found"
sudo chroot live_boot/chroot apt-get install -y --no-install-recommends \
    linux-image-generic live-boot live-boot-initramfs-tools

# Cài đặt môi trường đồ họa cơ bản cho Window Manager của bạn
sudo chroot live_boot/chroot apt-get install -y --no-install-recommends \
    xserver-xorg-core xserver-xorg-input-libinput xinit libx11-6

echo "=== 4. Biên dịch DuyKhanhWM và tích hợp vào hệ thống ==="
if [ -f "duykhanhwm.c" ]; then
    gcc duykhanhwm.c -o duykhanhwm -lX11
    sudo cp duykhanhwm live_boot/chroot/usr/local/bin/duykhanhwm
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanhwm
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

echo "=== 7. Sao chép Nhân Linux và cấu hình Menu Boot ==="
# Tìm và copy chính xác file Kernel vừa cài vào thư mục ISO
sudo cp $(ls -v live_boot/chroot/boot/vmlinuz-* | grep -v efi | head -n 1) live_boot/image/live/vmlinuz
sudo cp $(ls -v live_boot/chroot/boot/initrd.img-* | head -n 1) live_boot/image/live/initrd.img

if [ -f "grub.cfg" ]; then
    cp grub.cfg live_boot/image/boot/grub/grub.cfg
else
    cat << EOF > live_boot/image/boot/grub/grub.cfg
set default=0
set timeout=5
menuentry "DuyKhanhOS Live (Mint Core)" {
    search --set=root --file /live/filesystem.squashfs
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF
fi

echo "=== 8. Đóng gói thành file ISO hoàn chỉnh ==="
grub-mkrescue -o duykhanh-os.iso live_boot/image

echo "=== THÀNH CÔNG: Đã tạo xong file duykhanh-os.iso ==="
