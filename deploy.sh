#!/bin/bash
# ============================================
# HNG13 DevOps Stage 1 - Automated Deployment
# Author: Ogunniran Philip
# Date: $(date)
# ============================================

# Exit immediately if a command fails
set -e

# Log file setup
LOG_FILE="deploy_$(date +%Y%m%d).log"
touch $LOG_FILE

# Error handling
trap 'echo "[ERROR] Script failed at line $LINENO. Check $LOG_FILE for details." | tee -a $LOG_FILE; exit 1' ERR

echo "========== Starting Deployment ==========" | tee -a $LOG_FILE

# --------------------------------------------
# STEP 1: Collect Parameters from User Input
# --------------------------------------------
read -p "Enter GitHub Repository URL: " REPO_URL
read -p "Enter Personal Access Token (PAT): " PAT
read -p "Enter branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter SSH username: " SSH_USER
read -p "Enter Server IP address: " SERVER_IP
read -p "Enter SSH key path: " SSH_KEY
read -p "Enter internal application port (container port): " APP_PORT

echo "Inputs received successfully." | tee -a $LOG_FILE

# --------------------------------------------
# STEP 2: Clone the Repository
# --------------------------------------------
echo "Cloning repository..." | tee -a $LOG_FILE

if [ -d "project" ]; then
    echo "Project directory exists. Pulling latest changes..." | tee -a $LOG_FILE
    cd project
    git pull
else
    git clone -b $BRANCH https://${PAT}@${REPO_URL#https://} project
    cd project
fi

echo "Repository cloned successfully." | tee -a $LOG_FILE

# Verify Dockerfile or docker-compose.yml
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    echo "✅ Docker configuration found." | tee -a $LOG_FILE
else
    echo "❌ No Dockerfile or docker-compose.yml found. Exiting..." | tee -a $LOG_FILE
    exit 1
fi

# --------------------------------------------
# STEP 3: Test SSH Connection
# --------------------------------------------
echo "Testing SSH connection to $SERVER_IP..." | tee -a $LOG_FILE
ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 "$SSH_USER@$SERVER_IP" "echo SSH connection successful." | tee -a $LOG_FILE

# --------------------------------------------
# STEP 4: Prepare Remote Environment
# --------------------------------------------
echo "Preparing remote environment..." | tee -a $LOG_FILE

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" << EOF
set -e
sudo apt update -y
sudo apt install -y docker.io docker-compose nginx
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable nginx
sudo systemctl start nginx
sudo usermod -aG docker $USER
EOF

echo "Remote environment setup complete." | tee -a $LOG_FILE

# --------------------------------------------
# STEP 5: Transfer Files to Server
# --------------------------------------------
echo "Transferring project files..." | tee -a $LOG_FILE
scp -i "$SSH_KEY" -r . "$SSH_USER@$SERVER_IP:/home/$SSH_USER/project"

# --------------------------------------------
# STEP 6: Deploy the Dockerized Application
# --------------------------------------------
echo "Deploying Docker application..." | tee -a $LOG_FILE

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" << EOF
cd /home/$SSH_USER/project
if [ -f "docker-compose.yml" ]; then
    sudo docker-compose down || true
    sudo docker-compose up -d --build
else
    sudo docker build -t stage1-app .
    sudo docker stop stage1-app || true
    sudo docker rm stage1-app || true
    sudo docker run -d -p $APP_PORT:$APP_PORT --name stage1-app stage1-app
fi
EOF

echo "Docker application deployed successfully." | tee -a $LOG_FILE

# --------------------------------------------
# STEP 7: Configure NGINX Reverse Proxy
# --------------------------------------------
echo "Configuring NGINX reverse proxy..." | tee -a $LOG_FILE

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" << EOF
sudo bash -c 'cat > /etc/nginx/sites-available/stage1 <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOL'

sudo ln -sf /etc/nginx/sites-available/stage1 /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
EOF

echo "NGINX reverse proxy configured." | tee -a $LOG_FILE

# --------------------------------------------
# STEP 8: Validate Deployment
# --------------------------------------------
echo "Validating deployment..." | tee -a $LOG_FILE
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "curl -I http://localhost" | tee -a $LOG_FILE

echo "========== Deployment Completed Successfully ==========" | tee -a $LOG_FILE
