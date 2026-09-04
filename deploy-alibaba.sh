#!/bin/bash

# Deploy LibreChat to Alibaba Cloud VPS
# Usage: 
# 1. Replace YOUR_VPS_IP with your actual Alibaba Cloud ECS IP
# 2. chmod +x deploy-alibaba.sh
# 3. ./deploy-alibaba.sh

VPS_IP="YOUR_VPS_IP"  # Thay bằng IP thực tế
MONGO_URI="mongodb+srv://thyychii2863_db_user:0pmSs4d1WUooNVGq@cluster0.ah1bpbl.mongodb.net/LibreChat"

echo "🚀 Starting LibreChat deployment to Alibaba Cloud VPS at $VPS_IP"

# Step 1: Update system and install Docker
echo "📦 Installing Docker and dependencies..."
ssh root@$VPS_IP << 'ENDSSH'
# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Install Git
apt-get install -y git

echo "✅ Docker installed successfully"
ENDSSH

# Step 2: Clone LibreChat repository
echo "📥 Cloning LibreChat repository..."
ssh root@$VPS_IP << 'ENDSSH'
cd /opt
git clone https://github.com/nhan7777/LibreChat.git
cd LibreChat
ENDSSH

# Step 3: Create .env file with MongoDB Atlas
echo "⚙️ Creating .env configuration..."
ssh root@$VPS_IP << ENDSSH
cd /opt/LibreChat
cat > .env << 'EOF'
# MongoDB Atlas
MONGO_URI=$MONGO_URI

# Server Configuration
HOST=0.0.0.0
PORT=3080
DOMAIN_CLIENT=http://$VPS_IP:3080
DOMAIN_SERVER=http://$VPS_IP:3080

# Session & Auth (generate secure keys)
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
CREDS_KEY=$(openssl rand -hex 32)
CREDS_IV=$(openssl rand -hex 16)

# API Keys - users provide their own
OPENAI_API_KEY=user_provided
ANTHROPIC_API_KEY=user_provided
GOOGLE_KEY=user_provided

# UI
APP_TITLE=LibreChat
HELP_AND_FAQ_URL=https://librechat.ai

# Authentication
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_UNVERIFIED_EMAIL_LOGIN=true

# Logging
DEBUG_LOGGING=false
CONSOLE_JSON=true
LOG_TO_FILE=false
EOF

echo "✅ .env file created"
ENDSSH

# Step 4: Build and start with Docker Compose
echo "🐳 Building and starting LibreChat..."
ssh root@$VPS_IP << 'ENDSSH'
cd /opt/LibreChat

# Build and start
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check status
docker-compose ps

# Show logs
echo "📋 Recent logs:"
docker-compose logs --tail=50

echo "✅ LibreChat deployed successfully!"
ENDSSH

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📍 Access LibreChat at: http://$VPS_IP:3080"
echo ""
echo "🔧 Useful commands:"
echo "  - View logs: ssh root@$VPS_IP 'cd /opt/LibreChat && docker-compose logs -f'"
echo "  - Restart: ssh root@$VPS_IP 'cd /opt/LibreChat && docker-compose restart'"
echo "  - Stop: ssh root@$VPS_IP 'cd /opt/LibreChat && docker-compose down'"
echo "  - Update: ssh root@$VPS_IP 'cd /opt/LibreChat && git pull && docker-compose up -d --build'"
echo ""
echo "⚠️ Note: For production, setup SSL/HTTPS with Nginx + Let's Encrypt"
