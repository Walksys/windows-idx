#!/usr/bin/env bash
set -e

WORKDIR="$HOME/windows-idx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

ISO_URL="https://archive.org/download/tiny11-23h2/tiny11%2023h2%20x64.iso"

ISO_FILE="tiny11.iso"
DISK_FILE="tiny11.qcow2"

echo "🧹 Cleaning old sessions..."

pkill -f qemu || true
pkill -f websockify || true
pkill -f novnc || true

rm -f nohup.out

echo "💽 Preparing disk..."

if [ ! -f "$DISK_FILE" ]; then
    qemu-img create -f qcow2 "$DISK_FILE" 64G
fi

echo "📥 Checking ISO..."

if [ ! -f "$ISO_FILE" ]; then
    wget -O "$ISO_FILE" "$ISO_URL"
fi

echo "🚀 Starting Windows VM..."

qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 8 \
    -m 16G \
    -machine q35 \
    -drive file="$DISK_FILE",if=virtio,format=qcow2 \
    -cdrom "$ISO_FILE" \
    -boot order=d \
    -vnc 0.0.0.0:0 \
    -net nic \
    -net user,hostfwd=tcp::3389-:3389 \
    -usb \
    -device usb-tablet \
    > qemu.log 2>&1 &

sleep 5

echo "🌐 Starting noVNC on port 6080..."

websockify --web=/usr/share/novnc/ 6080 localhost:5900 > novnc.log 2>&1 &

sleep 3

echo ""
echo "✅ Windows started successfully!"
echo ""
echo "🔗 Open noVNC:"
echo "http://localhost:6080/vnc.html"
echo ""
echo "📌 IDX Preview Port:"
echo "6080"
echo ""
echo "🖥️ RDP Port داخل الويندوز:"
echo "3389"
