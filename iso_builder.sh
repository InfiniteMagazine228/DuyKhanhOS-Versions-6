#!/bin/bash
set -e

echo "=== 1. Tao cau truc thu muc Live ISO ==="
WORKDIR=$(pwd)
mkdir -p live_boot/chroot
mkdir -p live_boot/image/live
mkdir -p live_boot/image/boot/grub

echo "=== 2. Tai he thong nen (Ubuntu/Mint Base) ==="
# SỬA LỖI: Dùng link archive chính thức, không dùng link trang chủ ubuntu.com
sudo debootstrap --arch=amd64 noble live_boot/chroot http://ubuntu.com

echo "=== 3. Cau hinh va cai dat Nhan (Kernel) + Do hoa ==="
sudo chroot live_boot/chroot apt-get update
# Cài đặt hạt nhân Linux hệ Live và các gói đồ họa X11 cơ bản
sudo chroot live_boot/chroot apt-get install -y --no-install-recommends \
    linux-image-generic live-boot live-boot-initramfs-tools \
    xserver-xorg-core xserver-xorg-input-libinput xinit libx11-6 xterm

echo "=== 4. Bien dich DuyKhanhWM va tich hop vao he thong ==="
if [ -f "duykhanhwm.c" ]; then
    gcc duykhanhwm.c -o duykhanhwm -lX11
    sudo cp duykhanhwm live_boot/chroot/usr/local/bin/duykhanhwm
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanhwm
    
    # Cấu hình tự động khởi động DuyKhanhWM và gọi script fetch thông tin
    echo -e "duykhanh-fetch\nexec duykhanhwm" | sudo tee live_boot/chroot/root/.xinitrc
else
    echo "Canh bao: Khong tim thay file duykhanhwm.c!"
fi

echo "=== 5. Dua script duykhanh-fetch vao he thong ==="
if [ -f "duykhanh-fetch.sh" ]; then
    sudo cp duykhanh-fetch.sh live_boot/chroot/usr/local/bin/duykhanh-fetch
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanh-fetch
fi

echo "=== 6. Nen he thong thanh file filesystem.squashfs ==="
sudo mksquashfs live_boot/chroot live_boot/image/live/filesystem.squashfs -noappend -e boot

echo "=== 7. Sao chep Nhan Linux vao thu muc boot cua ISO ==="
sudo cp $(ls -v live_boot/chroot/boot/vmlinuz-* | grep -v efi | head -n 1) live_boot/image/live/vmlinuz
sudo cp $(ls -v live_boot/chroot/boot/initrd.img-* | head -n 1) live_boot/image/live/initrd.img

echo "=== 8. Cau hinh Menu Boot (GRUB) ==="
if [ -f "grub.cfg" ]; then
    cp grub.cfg live_boot/image/boot/grub/grub.cfg
fi

echo "=== 9. Dong goi thanh file ISO hoan chinh ==="
grub-mkrescue -o duykhanh-os.iso live_boot/image
echo "=== THANH CONG: Da tao xong file duykhanh-os.iso ==="
