#!/bin/bash

set -e

HF_TOKEN=""
REPO="Moinator/qwen30b-l4-bundle"

echo "[1/6] Installing dependencies..."
apt install -y pipx

export PATH="$HOME/.local/bin:$PATH"

if ! command -v hf >/dev/null 2>&1; then
pipx install huggingface_hub
fi

echo "[2/6] Logging into Hugging Face..."
hf auth login --token "$HF_TOKEN"

echo "[3/6] Downloading bundle..."
mkdir -p /opt/qwen

hf download "Moinator/qwen30b-l4-bundle" --repo-type dataset --include "*" --local-dir /opt/qwen

echo "[3.5/6] Fixing permissions..."

chmod +x /opt/qwen/build/bin/llama-server || true

echo "[4/6] Creating launcher..."

cat >/opt/qwen/run.sh <<'EOF'
#!/bin/bash

exec /opt/qwen/build/bin/llama-server 
-m /opt/qwen/Qwen30B/Qwen3VL-30B-A3B-Instruct-Q4_K_M.gguf 
--mmproj /opt/qwen/Qwen30B/mmproj-Qwen3VL-30B-A3B-Instruct-F16.gguf 
-ngl 999 
--host 0.0.0.0 
--port 8080
EOF

chmod +x /opt/qwen/run.sh

echo "[5/6] Creating systemd service..."

cat >/etc/systemd/system/qwen.service <<'EOF'
[Unit]
Description=Qwen3-VL Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/qwen
ExecStart=/opt/qwen/run.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[6/6] Starting service..."

systemctl daemon-reload
systemctl enable qwen
systemctl restart qwen

echo
echo "Service status:"
systemctl --no-pager status qwen || true

echo
echo "Logs:"
echo "journalctl -u qwen -f"
