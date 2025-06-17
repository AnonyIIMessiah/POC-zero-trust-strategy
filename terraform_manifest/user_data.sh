#!/bin/bash

# Exit on error
set -e

# Replace this with your API Gateway URL at runtime via script/template interpolation
API_URL_PLACEHOLDER="${api_url}"
USER_POOL_ID="${user_pool_id}"
USER_POOL_WEB_CLIENT_ID="${user_pool_web_client_id}"
APP_REGION="ap-south-1"
APP_AUTH_DOMAIN="${app_auth_domain}"
REDIRECT_SIGN_IN="${redirect_sign_in}"
REDIRECT_SIGN_OUT="${redirect_sign_out}"
RESPONSE_TYPE="code"
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
echo "REACT_APP_USER_POOL_ID=$USER_POOL_ID" >> "$APP_DIR/.env"
echo "REACT_APP_USER_POOL_WEB_CLIENT_ID=$USER_POOL_WEB_CLIENT_ID" >> "$APP_DIR/.env"
echo "REACT_APP_REGION=$APP_REGION" >> "$APP_DIR/.env"
echo "REACT_APP_AUTH_DOMAIN=$APP_AUTH_DOMAIN" >> "$APP_DIR/.env"
echo "REACT_APP_REDIRECT_SIGN_IN=$REDIRECT_SIGN_IN" >> "$APP_DIR/.env"
echo "REACT_APP_REDIRECT_SIGN_OUT=$REDIRECT_SIGN_OUT" >> "$APP_DIR/.env"
echo "REACT_APP_RESPONSE_TYPE=$RESPONSE_TYPE" >> "$APP_DIR/.env"

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
