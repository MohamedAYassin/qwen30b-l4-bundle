#!/bin/bash

set -e

HF_TOKEN=""
REPO="Moinator/qwen30b-l4-bundle"

echo "Installing dependencies..."
apt update
apt install -y python3-pip

pip install -U huggingface_hub

mkdir -p /opt/qwen

echo "Logging into Hugging Face..."
hf auth login --token "$HF_TOKEN"

echo "Downloading bundle..."
hf download 
"$REPO" 
--repo-type dataset 
--local-dir /opt/qwen

echo "Creating service..."

cat >/etc/systemd/system/qwen.service <<'EOF'
[Unit]
Description=Qwen VL Server
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/qwen
ExecStart=/opt/qwen/build/bin/llama-server 
-m /opt/qwen/Qwen30B/Qwen3VL-30B-A3B-Instruct-Q4_K_M.gguf 
--mmproj /opt/qwen/Qwen30B/mmproj-Qwen3VL-30B-A3B-Instruct-F16.gguf 
-ngl 999 
--host 0.0.0.0 
--port 8080

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable qwen
systemctl start qwen

echo "Done."

echo "Check status:"
echo "systemctl status qwen"

echo "Logs:"
echo "journalctl -u qwen -f"
