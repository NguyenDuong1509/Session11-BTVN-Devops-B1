#!/usr/bin/env bash
# Script tự động cấu hình Nginx Reverse Proxy trên Ubuntu VPS

set -e

echo "[1/3] Cài đặt Nginx..."
sudo apt-get update -y && sudo apt-get install -y nginx

echo "[2/3] Cấu hình Reverse Proxy chuyển cổng 80 sang 3000..."
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak_$(date +%Y%m%d) || true

sudo tee /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://localhost:3000;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

echo "[3/3] Kiểm tra cú pháp và reload Nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "[v] Cấu hình Nginx Reverse Proxy hoàn tất thành công!"
