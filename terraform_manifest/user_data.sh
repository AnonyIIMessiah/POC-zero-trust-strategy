#!/bin/bash

# Exit on error
set -e

# Replace this with your API Gateway URL at runtime via script/template interpolation
API_URL_PLACEHOLDER="${api_url}"

# System update
yum update -y

# Install Git
yum install git -y

# Clone the project
git clone https://github.com/AnonyIIMessiah/POC-zero-trust-strategy.git
cd POC-zero-trust-strategy/

# Set React app directory
APP_DIR="03_frontend"

# Inject API Gateway URL into .env
echo "REACT_APP_API_URL=$API_URL_PLACEHOLDER" > "$APP_DIR/.env"

# Install Nginx
dnf install nginx -y

# Install Node.js via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Build the React app
cd "$APP_DIR"
npm install
npm run build

# Deploy to Nginx
rm -rf /usr/share/nginx/html/*
cp -r build/* /usr/share/nginx/html/

# Nginx config
cat <<EOF > /etc/nginx/conf.d/react_app.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /usr/share/nginx/html;
    index index.html;
    server_name _;
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Start Nginx
systemctl restart nginx
systemctl enable nginx

echo "✅ Deployment finished. React app should be live."
