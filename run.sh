#!/usr/bin/env bash
set -e

# الانتقال لمكان مضمون للعمل
WORKDIR="$HOME/windows-idx"
cd $HOME
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 1. روابط وأسماء الملفات لنسخة حديثة (Windows Server 2022)
ISO_URL="https://go.microsoft.com/fwlink/?linkid=2345730&clcid=0x409&culture=en-us&country=us"
ISO_FILE="win2025.iso"
DISK_FILE="win2025.qcow2"
DISK_SIZE="64G"
PINGGY_TOKEN="kzm1eczI7Bb"

# 2. تنظيف العمليات القديمة تماماً
pkill -f "ssh" || true
pkill -f "qemu" || true
rm -f vnc.log rdp.log
sleep 2

# 3. إنشاء ملف القرص لو مش موجود
if [ ! -f "$DISK_FILE" ]; then
    echo "💾 Creating disk... please wait"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

# 4. التأكد من وجود ملف الأيزو الحديث
if [ ! -f "$ISO_FILE" ]; then
    echo "📥 Downloading Windows Server 2022 ISO... this will take some time"
    # استخدام wget مع توجيه الإخراج لعرض تقدم التحميل
    wget --show-progress -O "$ISO_FILE" "$ISO_URL"
fi

echo "🚀 جاري فتح نفق VNC للبدء في التثبيت..."

# 5. فتح نفق VNC (المنفذ 5900) باستخدام خاصية Force
ssh -p 443 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 \
    -R0:localhost:5900 \
    ${PINGGY_TOKEN}+force+tcp@a.pinggy.io > vnc.log 2>&1 &

echo "⏳ انتظر جلب رابط الـ VNC..."
sleep 15

# 6. عرض الرابط
VNC_URL=$(grep -oE '[a-zA-Z0-9.-]+\.pinggy\.link:[0-9]+' vnc.log | head -n 1)

echo "------------------------------------------------"
if [ -z "$VNC_URL" ]; then
    echo "❌ فشل جلب الرابط. بص على الـ Log:"
    cat vnc.log
else
    echo "✅ رابط الـ VNC الجديد (افتحه في VNC Viewer):"
    echo "🔗 العنوان: $VNC_URL"
    echo "------------------------------------------------"
    echo "💡 ملاحظة: التحميل الأولي لـ ISO قد يأخذ وقتاً (حوالي 5 جيجا)"
fi

# 7. تشغيل المحاكي في مرحلة التثبيت
echo "🎮 جاري تشغيل المثبت (Installation Mode)..."
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host -smp 4 -m 8G -machine q35 \
    -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -cdrom "$ISO_FILE" \
    -boot order=d \
    -vnc :0 \
    -net user,hostfwd=tcp::3389-:3389 -net nic \
    -usb -device usb-tablet
