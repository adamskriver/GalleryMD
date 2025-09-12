#!/bin/bash
# Post-installation setup script for GalleryMD
# Run this after Ubuntu is successfully installed
# Usage: ssh pewter@VM_IP "bash -s" < post-install.sh

set -e
echo "🚀 Setting up GalleryMD environment..."

# Update package lists
sudo apt update

# Install basic dependencies
echo "📦 Installing dependencies..."
sudo apt install -y curl git unzip

# Install Deno
echo "🦕 Installing Deno..."
curl -fsSL https://deno.land/install.sh | sh
echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.bashrc
echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.bashrc
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Create app directories
echo "📂 Creating application directories..."
mkdir -p ~/gallerymd/docs
mkdir -p ~/gallerymd/public

# Clone from GitHub if repo exists
echo "📥 Cloning from GitHub repository..."
git clone https://github.com/adamskriver/GalleryMD.git ~/temp-repo || {
    echo "Repository clone failed or doesn't exist. Setting up manually."
}

# Copy files from repo or create them
if [ -d ~/temp-repo ]; then
    echo "Copying files from repository..."
    cp -r ~/temp-repo/* ~/gallerymd/
    rm -rf ~/temp-repo
else
    # Create basic files for demo if repo clone failed
    echo "Creating sample application files..."
    
    # Create a demo case study
    mkdir -p ~/gallerymd/docs/demo
    cat > ~/gallerymd/docs/demo/CASESTUDY.md << 'EOF'
# Sample Case Study

This is a sample case study for the GalleryMD application.

## Overview

This demonstrates the functionality of the GalleryMD markdown rendering system.
EOF
fi

# Create systemd service file
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/gallerymd.service > /dev/null << EOF
[Unit]
Description=GalleryMD Server
After=network.target

[Service]
Type=simple
User=pewter
WorkingDirectory=/home/pewter/gallerymd
Environment="PORT=3000"
Environment="MD_ROOT=/home/pewter/gallerymd/docs"
ExecStart=/home/pewter/.deno/bin/deno run --allow-net --allow-read --allow-env server.ts
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Set correct permissions
sudo chown -R $(whoami):$(whoami) ~/gallerymd

# Enable service
sudo systemctl enable gallerymd.service

echo "✅ Setup complete!"
echo "Next steps:"
echo "1. Copy your server.ts and other application files to ~/gallerymd/"
echo "2. Copy your case study files to ~/gallerymd/docs/"
echo "3. Start the service: sudo systemctl start gallerymd.service"
echo "4. Check status: sudo systemctl status gallerymd.service"
