#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
sudo yum install git -y

# --- Configuration ---
# Set the name of your React app folder
APP_DIR="frontend"

# --- 1. System Update and Nginx Installation ---
echo "🚀 Starting deployment..."
echo "Updating system packages..."
sudo yum update -y # 'yum' is aliased to 'dnf' in AL2023, so this works fine.

echo "Installing Nginx..."
# This is the corrected command for Amazon Linux 2023
sudo dnf install nginx -y

# --- 2. Install Node.js and npm using nvm ---
echo "Installing Node.js and npm via nvm..."
# The nvm install script might change, check https://github.com/nvm-sh/nvm for the latest version
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source nvm to use it in this script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install the latest Long-Term Support (LTS) version of Node.js
nvm install --lts
nvm use --lts

# Verify installation
echo "Node version:"
node -v
echo "npm version:"
npm -v

# --- 3. Build the React Application ---
echo "Building the React application..."
if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory '$APP_DIR' not found!"
    echo "Please make sure your React app folder is in the current directory."
    exit 1
fi

cd $APP_DIR

echo "Installing dependencies..."
npm install

echo "Running the production build..."
npm run build

# --- 4. Configure Nginx to Serve the App ---
echo "Configuring Nginx..."

# Copy the built React app to Nginx's web root directory
sudo rm -rf /usr/share/nginx/html/*
sudo cp -r build/* /usr/share/nginx/html/

# Create a custom Nginx configuration for the React app
# This handles client-side routing (e.g., React Router)
sudo tee /etc/nginx/conf.d/react_app.conf > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # The root directory for our static files
    root /usr/share/nginx/html;
    index index.html;

    server_name _;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying index.html
        try_files $uri $uri/ /index.html;
    }
}
EOF

# --- 5. Start and Enable Nginx ---
echo "Starting and enabling Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Deployment successful! Your application is now live."