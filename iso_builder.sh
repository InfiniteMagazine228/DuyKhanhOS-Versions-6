#!/bin/bash
set -e

echo "=== 1. Tao cau truc thu muc Live ISO ==="
WORKDIR=$(pwd)
mkdir -p live_boot/chroot
mkdir -p live_boot/image/live
mkdir -p live_boot/image/boot/grub

echo "=== 2. Tai he thong nen (Ubuntu/Mint Base) ==="
sudo debootstrap --arch=amd64 noble live_boot/chroot https://archive.ubuntu.com/ubuntu/

echo "=== 3. Cau hinh va cai dat Nhan (Kernel) + Do hoa ==="
# SỬA LỖI: Thêm kho universe để nhận diện các gói live-boot và xterm
echo "deb http://archive.ubuntu.com/ubuntu noble main universe" | sudo tee live_boot/chroot/etc/apt/sources.list
sudo chroot live_boot/chroot apt-get update

sudo chroot live_boot/chroot apt-get install -y --no-install-recommends \
    linux-image-generic live-boot live-boot-initramfs-tools \
    xserver-xorg-core xserver-xorg-input-libinput xinit libx11-6 xterm

echo "=== 4. Bien dich DuyKhanhWM va tich hop vao he thong ==="
if [ -f "duykhanhwm.c" ]; then
    gcc duykhanhwm.c -o duykhanhwm -lX11
    sudo cp duykhanhwm live_boot/chroot/usr/local/bin/duykhanhwm
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanhwm
    
    # Cấu hình khởi chạy đồ họa tự gọi DuyKhanhWM
    echo -e "duykhanh-fetch\nexec duykhanhwm" | sudo tee live_boot/chroot/root/.xinitrc
else
    echo "Canh bao: Khong tim thay file duykhanhwm.c!"
fi

echo "=== 5. Dua script duykhanh-fetch vao he thong ==="
if [ -f "duykhanh-fetch.sh" ]; then
    sudo cp duykhanh-fetch.sh live_boot/chroot/usr/local/bin/duykhanh-fetch
    sudo chmod +x live_boot/chroot/usr/local/bin/duykhanh-fetch
    
    # Cấu hình hiển thị script fetch ngay lập tức khi vào CLI Boot Mode (Chế độ 2)
    echo "/usr/local/bin/duykhanh-fetch" | sudo tee -a live_boot/chroot/root/.bashrc
fi

echo "=== 5.5 Cấu hình Tự động đăng nhập (Autologin cho tài khoản Root) ==="
# Tạo thư mục cấu hình dịch vụ khởi động tty1
sudo mkdir -p live_boot/chroot/etc/systemd/system/getty@tty1.service.d/

# Ghi cấu hình ép hệ thống tự động đăng nhập quyền root mà không hỏi mật khẩu
cat << EOF | sudo tee live_boot/chroot/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

# Đảm bảo file .bashrc của Root sẽ tự động gọi giao diện đồ họa sau khi đăng nhập xong
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi' | sudo tee -a live_boot/chroot/root/.bashrc


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
