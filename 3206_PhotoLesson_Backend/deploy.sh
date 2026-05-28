#!/bin/bash
# PhotoLesson EC2 Setup & Deploy Script

# 1. Install Java 17
sudo dnf install -y java-17-amazon-corretto-devel

# 2. Create app directory
mkdir -p /home/ec2-user/photolesson/uploads

# 3. Set environment variables
cat > /home/ec2-user/photolesson/.env << 'ENVEOF'
DB_HOST=PLACEHOLDER_DB_HOST
DB_USERNAME=admin
DB_PASSWORD=PhotoLesson2026!
JWT_SECRET=photolesson-prod-secret-key-for-jwt-token-generation-must-be-at-least-256-bits-long
ENVEOF

# 4. Create systemd service
sudo tee /etc/systemd/system/photolesson.service > /dev/null << 'EOF'
[Unit]
Description=PhotoLesson Backend
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/photolesson
EnvironmentFile=/home/ec2-user/photolesson/.env
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=prod /home/ec2-user/photolesson/app.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable photolesson

echo "Setup complete! Upload app.jar and run: sudo systemctl start photolesson"
