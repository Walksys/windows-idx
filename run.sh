#!/usr/bin/env bash
set -e

# مكان العمل
WORKDIR="$HOME/windows-idx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# أسماء الملفات
ISO_URL="https://archive.org/download/windows-10-lite-edition-19h2-x64/Windows%2010%20Lite%20Edition%2019H2%20x64.iso"
ISO_FILE="win10.iso"
DISK_FILE="win10.qcow2"
LINKS_FILE="links.txt"

# 1. تنظيف القديم
pkill -f "ssh" || true
pkill -f "qemu" || true
rm -f tunnels.log "$LINKS_FILE"

# 2. إنشاء القرص والتحميل (لو مش موجودين)
if [ ! -f "$DISK_FILE" ]; then qemu-img create -f qcow2 "$DISK_FILE" 64G; fi
if [ ! -f "$ISO_FILE" ]; then wget -O "$ISO_FILE" "$ISO_URL"; fi

echo "🚀 جاري فتح الأنفاق وتسجيلها في الملف..."

# 3. فتح النفق (Serveo)
ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 mwILtcPhp4j+tcp@free.pinggy.io > tunnels.log 2>&1 &

# انتظر لحظة عشان اللينك يتولد
sleep 15

# 4. استخراج الروابط وحفظها في ملف links.txt
echo "--- روابط الويندوز الخاصة بك ---" > "$LINKS_FILE"
echo "تاريخ التشغيل: $(date)" >> "$LINKS_FILE"
grep -oE 'forwarding from [a-zA-Z0-9.-]+' tunnels.log | sed 's/forwarding from /🔗 /' >> "$LINKS_FILE"
echo "------------------------------" >> "$LINKS_FILE"

echo "✅ تم حفظ الروابط في ملف: $LINKS_FILE"
cat "$LINKS_FILE"

# 5. تشغيل الويندوز (16GB RAM / 7 Cores)
echo "🎮 جاري تشغيل المثبت (Installation Mode)..."
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host -smp 7 -m 16G -machine q35 \
    -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -cdrom "$ISO_FILE" \
    -boot order=d \
    -vnc :0 \
    -net user,hostfwd=tcp::3389-:3389 -net nic \
    -usb -device usb-tablet
