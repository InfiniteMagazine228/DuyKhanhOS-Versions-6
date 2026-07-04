#!/bin/bash
set -e # Dừng script ngay nếu có bất kỳ lệnh nào bị lỗi

echo "=== [1/6] Cài đặt công cụ chỉnh sửa ISO ==="
sudo apt-get update
sudo apt-get install -y squashfs-tools xorriso intel-microcode gcc libx11-dev wget

echo "=== [2/6] Biên dịch DuyKhanhWM GUI C ==="
gcc -o duykhanhwm duykhanhwm.c -lX11

echo "=== [3/6] Tải ISO Arch Linux chính thức mới nhất ==="
mkdir -p iso_source iso_mnt squashfs_root custom_iso
wget -q -O archlinux.iso https://pkgbuild.com

echo "=== [4/6] Giải nén cấu trúc ISO gốc ==="
xorriso -osirrox on -indev archlinux.iso -extract / custom_iso/
chmod -R +w custom_iso/
sudo unsquashfs -d squashfs_root custom_iso/arch/x86_64/airootfs.sfs

echo "=== [5/6] Thay thế cấu hình và chèn đồ chơi DuyKhanhOS (Kali-vibe) ==="
sudo cp duykhanhwm squashfs_root/usr/local/bin/
if [ -f "duykhanhfetch.sh" ]; then
    sudo cp duykhanhfetch.sh squashfs_root/usr/local/bin/duykhanhfetch
    sudo chmod +x squashfs_root/usr/local/bin/duykhanhfetch
fi

sudo mkdir -p squashfs_root/etc/skel/
echo "export GTK_THEME=Adwaita-dark" | sudo tee squashfs_root/etc/skel/.xinitrc
echo "xsetroot -solid '#0f141c'" | sudo tee -a squashfs_root/etc/skel/.xinitrc
echo "(alacritty || xterm || xfce4-terminal) -e duykhanhfetch &" | sudo tee -a squashfs_root/etc/skel/.xinitrc
echo "exec duykhanhwm" | sudo tee -a squashfs_root/etc/skel/.xinitrc

sudo mkdir -p custom_iso/boot/grub/
echo "set timeout=5" | sudo tee custom_iso/boot/grub/grub.cfg
echo "set default=0" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "set menu_color_normal=light-blue/black" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "set menu_color_highlight=black/light-blue" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "menuentry 'Khởi động DuyKhanhOS v6 (Kali-vibe Đồ Họa)' {" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "    linux /boot/vmlinuz-linux archisobasedir=arch cow_spacesize=10G" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "    initrd /boot/initramfs-linux.img" | sudo tee -a custom_iso/boot/grub/grub.cfg
echo "}" | sudo tee -a custom_iso/boot/grub/grub.cfg

echo "=== [6/6] Đóng gói lại thành file ISO và IMG của DuyKhanhOS ==="
sudo rm -f custom_iso/arch/x86_64/airootfs.sfs
sudo mksquashfs squashfs_root custom_iso/arch/x86_64/airootfs.sfs -comp xz
mkdir -p out_iso

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "DUYKHANHOS_V6" \
  -eltorito-boot boot/syslinux/isolinux.bin \
  -eltorito-catalog boot/syslinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr custom_iso/boot/syslinux/isohdpfx.bin \
  -output out_iso/duykhanhos-v6.iso custom_iso/

cp out_iso/duykhanhos-v6.iso out_iso/duykhanhos-v6.img
echo "🎉 Build hoàn tất xuất sắc!"
