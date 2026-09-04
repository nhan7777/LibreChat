# Deploy LibreChat lên Alibaba Cloud

Hướng dẫn đầy đủ để deploy LibreChat lên Alibaba Cloud ECS với MongoDB Atlas.

## 📋 Yêu cầu

- Tài khoản Alibaba Cloud (có thẻ credit card để verify)
- MongoDB Atlas database (đã có sẵn)
- MacOS/Linux với SSH

## 💰 Chi phí dự kiến

| Cấu hình | Giá/tháng | RAM | Phù hợp |
|---|---|---|---|
| ecs.t5-lc1m1.small | ~$4 | 1GB | Test, traffic thấp |
| ecs.t5-lc1m2.small | ~$8 | 2GB | **Khuyên dùng** |
| ecs.t5-lc2m4.small | ~$15 | 4GB | Traffic cao |

**Free trial:** $90-300 credit (~3-6 tháng miễn phí)

---

## 🚀 Các bước thực hiện

### Bước 1: Đăng ký Alibaba Cloud

1. Truy cập: https://www.alibabacloud.com/
2. Click **"Free Trial"** → Đăng ký
3. Xác minh email + thẻ credit card (không bị charge)
4. Nhận $90-300 credit tùy region

### Bước 2: Tạo ECS Instance

1. Vào **Console** → **Elastic Compute Service**
2. Click **"Create Instance"**

**Cấu hình khuyên dùng:**
```
Billing Method: Pay-As-You-Go
Region: Singapore (ap-southeast-1)
Zone: Random
Instance Type: ecs.t5-lc1m2.small (1 vCPU, 2GB RAM)
Image: Ubuntu Server 22.04 64bit
System Disk: 40GB Ultra Disk
Network Type: VPC
Bandwidth: Pay-By-Traffic, 1 Mbps
Security Group: Create new, allow ports 22, 80, 443, 3080
```

3. Set **Login Password** (root user)
4. Click **"Preview"** → **"Create"**
5. Đợi ~2 phút cho instance khởi động

### Bước 3: Cấu hình Security Group

Đảm bảo Security Group cho phép các port:

```
Port 22   (SSH)
Port 80   (HTTP)
Port 443  (HTTPS)
Port 3080 (LibreChat)
```

**Cách thêm port:**
1. Vào **Security Groups** → Chọn group của bạn
2. Click **"Add Rules"** → **"Inbound"**
3. Thêm rule:
   - Port Range: 3080/3080
   - Authorization Object: 0.0.0.0/0
   - Priority: 1

### Bước 4: Lấy Public IP

1. Vào **Instances** → Tìm instance vừa tạo
2. Copy **Public IP Address** (ví dụ: `47.128.55.123`)

### Bước 5: Deploy LibreChat

**A. Sử dụng script tự động:**

1. Mở file `deploy-alibaba.sh`
2. Thay `YOUR_VPS_IP` bằng IP thực tế:
   ```bash
   VPS_IP="47.128.55.123"  # Thay IP của bạn
   ```

3. Chạy script:
   ```bash
   chmod +x deploy-alibaba.sh
   ./deploy-alibaba.sh
   ```

Script sẽ tự động:
- Cài Docker, Docker Compose, Git
- Clone LibreChat repository
- Tạo file .env với MongoDB Atlas
- Build và start LibreChat

**B. Deploy thủ công (nếu script lỗi):**

```bash
# 1. SSH vào VPS
ssh root@YOUR_VPS_IP

# 2. Update system
apt-get update && apt-get upgrade -y

# 3. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 4. Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 5. Install Git
apt-get install -y git

# 6. Clone LibreChat
cd /opt
git clone https://github.com/nhan7777/LibreChat.git
cd LibreChat

# 7. Create .env file
cat > .env << 'EOF'
MONGO_URI=mongodb+srv://thyychii2863_db_user:0pmSs4d1WUooNVGq@cluster0.ah1bpbl.mongodb.net/LibreChat
HOST=0.0.0.0
PORT=3080
DOMAIN_CLIENT=http://YOUR_VPS_IP:3080
DOMAIN_SERVER=http://YOUR_VPS_IP:3080
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
CREDS_KEY=$(openssl rand -hex 32)
CREDS_IV=$(openssl rand -hex 16)
OPENAI_API_KEY=user_provided
ANTHROPIC_API_KEY=user_provided
GOOGLE_KEY=user_provided
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
EOF

# Thay YOUR_VPS_IP trong .env
sed -i "s/YOUR_VPS_IP/$(curl -s ifconfig.me)/g" .env

# 8. Start LibreChat
docker-compose up -d

# 9. Check logs
docker-compose logs -f
```

### Bước 6: Truy cập LibreChat

Mở trình duyệt: `http://YOUR_VPS_IP:3080`

---

## 🔧 Quản lý sau khi deploy

### Xem logs
```bash
ssh root@YOUR_VPS_IP 'cd /opt/LibreChat && docker-compose logs -f'
```

### Restart
```bash
ssh root@YOUR_VPS_IP 'cd /opt/LibreChat && docker-compose restart'
```

### Stop
```bash
ssh root@YOUR_VPS_IP 'cd /opt/LibreChat && docker-compose down'
```

### Update LibreChat
```bash
ssh root@YOUR_VPS_IP 'cd /opt/LibreChat && git pull && docker-compose up -d --build'
```

---

## 🔒 Setup HTTPS (Production)

Để setup domain + SSL certificate:

```bash
# 1. Point domain to VPS IP (ví dụ: chat.yourdomain.com)

# 2. Install Nginx và Certbot
ssh root@YOUR_VPS_IP
apt-get install -y nginx certbot python3-certbot-nginx

# 3. Create Nginx config
cat > /etc/nginx/sites-available/librechat << 'EOF'
server {
    listen 80;
    server_name chat.yourdomain.com;

    location / {
        proxy_pass http://localhost:3080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# 4. Enable site
ln -s /etc/nginx/sites-available/librechat /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# 5. Get SSL certificate
certbot --nginx -d chat.yourdomain.com

# 6. Update .env
cd /opt/LibreChat
sed -i 's|http://|https://|g' .env
sed -i 's|:3080||g' .env
docker-compose restart
```

---

## 📊 So sánh: Alibaba Cloud vs Render

| Tiêu chí | Alibaba Cloud | Render |
|---|---|---|
| **Giá** | $4-8/tháng | Free |
| **Sleep** | Không bao giờ | Sau 15 phút |
| **RAM** | 1-2 GB | 512 MB |
| **Setup** | Phức tạp | Dễ |
| **Control** | Full control | Hạn chế |
| **SSH Access** | Có | Không |

---

## ❓ Troubleshooting

### Port 3080 không truy cập được
- Kiểm tra Security Group đã mở port 3080
- Kiểm tra firewall: `ufw status`

### Docker không start
```bash
systemctl status docker
systemctl start docker
```

### Out of memory
- Tăng RAM lên 2GB (ecs.t5-lc1m2.small)
- Hoặc thêm swap:
```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

---

## 🎯 Kết luận

**Ưu điểm:**
- Always-on, không sleep
- Rẻ ($4-8/tháng)
- Full control
- Performance tốt

**Nhược điểm:**
- Setup phức tạp hơn
- Cần quản lý VPS
- Cần credit card

**Phù hợp cho:** Production, dự án dài hạn, cần always-on
