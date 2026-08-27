#!/usr/bin/env bash
set -euo pipefail

# Ensure running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script with sudo: sudo $0"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

echo "==> 1. Removing all silent & sleep overrides..."
rm -rf /etc/systemd/system/plymouth-quit.service.d \
       /etc/systemd/system/sddm.service.d \
       /etc/systemd/system/systemd-reboot.service.d \
       /etc/systemd/system/systemd-poweroff.service.d \
       /etc/systemd/system/systemd-halt.service.d \
       /etc/systemd/system/reboot.target.wants/plymouth-reboot.service \
       /etc/systemd/system/poweroff.target.wants/plymouth-poweroff.service \
       /etc/systemd/system/halt.target.wants/plymouth-halt.service \
       /etc/systemd/system.conf.d/00-silent.conf \
       /usr/share/plymouth/themes/rice \
       /boot/grub/themes/rice-splash.png \
       /boot/splash-rice.bmp

systemctl unmask systemd-networkd-wait-online.service 2>/dev/null || true

echo "==> 2. Enabling Full Verbose [OK] Status Streaming for systemd..."
mkdir -p /etc/systemd/system.conf.d
cat << 'SYSCONF' > /etc/systemd/system.conf.d/00-verbose.conf
[Manager]
ShowStatus=yes
StatusUnitFormat=combined
DefaultStandardOutput=journal+console
DefaultStandardError=journal+console
SYSCONF

CMDLINE_PARAMS="root=PARTUUID=c2a17c08-c92a-4428-a262-35445c8205a7 zswap.enabled=0 rw rootfstype=btrfs systemd.show_status=1 systemd.status_unit_format=combined"
echo "$CMDLINE_PARAMS" > /etc/kernel/cmdline

echo "==> 3. Configuring GRUB UKI boot entry..."
cat << 'UKIGRUB' > /etc/grub.d/09_uki
#!/bin/sh
cat << 'CFGEOF'
menuentry 'Arch Linux' --class arch --class gnu-linux --class gnu --class os {
  search --no-floppy --fs-uuid --set=root 4884-4E49
  echo 'Loading Arch Linux...'
  linux /EFI/Linux/arch-linux.efi root=PARTUUID=c2a17c08-c92a-4428-a262-35445c8205a7 zswap.enabled=0 rw rootfstype=btrfs systemd.show_status=1 systemd.status_unit_format=combined
}
CFGEOF
UKIGRUB
chmod +x /etc/grub.d/09_uki
chmod -x /etc/grub.d/10_linux || true
rm -f /etc/grub.d/15_uki

echo "==> 4. Updating /etc/default/grub..."
python3 -c "
import re

path = '/etc/default/grub'
with open(path, 'r') as f:
    content = f.read()

content = re.sub(r'GRUB_CMDLINE_LINUX_DEFAULT=.*',
                 'GRUB_CMDLINE_LINUX_DEFAULT=\"systemd.show_status=1 systemd.status_unit_format=combined\"',
                 content)
content = re.sub(r'GRUB_BACKGROUND=.*', '', content)

with open(path, 'w') as f:
    f.write(content)
print('  ✓ Updated /etc/default/grub with verbose status')
"

echo "==> 5. Restoring /etc/mkinitcpio.conf (default HOOKS)..."
python3 -c "
import re

path = '/etc/mkinitcpio.conf'
with open(path, 'r') as f:
    content = f.read()

content = re.sub(r'HOOKS=\(base udev plymouth ', 'HOOKS=(base udev ', content)
with open(path, 'w') as f:
    f.write(content)
print('  ✓ Cleaned mkinitcpio.conf HOOKS')
"

echo "==> 6. Cleaning UKI preset options..."
python3 -c "
import re

path = '/etc/mkinitcpio.d/linux.preset'
with open(path, 'r') as f:
    content = f.read()

content = re.sub(r'default_options=.*', 'default_options=\"\"', content)
with open(path, 'w') as f:
    f.write(content)
print('  ✓ Cleaned UKI default_options in linux.preset')
"

echo "==> 7. Regenerating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> 8. Regenerating UKI Initramfs..."
mkinitcpio -P

echo ""
echo "=========================================================================="
echo "✔ Full Verbose Boot [OK] Status Streams Enabled for Boot & Shutdown! ✔"
echo "=========================================================================="
