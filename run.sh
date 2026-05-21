#!/usr/bin/env bash
set -e

WORKDIR="$HOME/windows-idx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

ISO_URL="https://archive.org/download/20348.169.210806-1117.-fe-release-svc-prod-1-server-x-64-fre-en-us/20348.169.210806-1117.FE_RELEASE_SVC_PROD1_SERVER_X64FRE_EN-US.ISO"

ISO_FILE="windows.iso"
DISK_FILE="windows.qcow2"

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
