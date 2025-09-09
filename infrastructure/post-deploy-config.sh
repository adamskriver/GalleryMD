# Post-Deployment Configuration Script

# This script provides commands to manually perform post-deployment configuration
# Run these commands on the VM after Ubuntu is installed

# Stop and disable UFW firewall to simplify access (not recommended for production)
sudo ufw disable

# Configure networking for easier access
sudo apt update
sudo apt install -y net-tools avahi-daemon

# Install deno if needed
curl -fsSL https://deno.land/install.sh | sh
echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.bashrc
echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Create sample case study directories
mkdir -p ~/gallerymd/docs/case1
mkdir -p ~/gallerymd/docs/case2

# Create sample case studies
cat > ~/gallerymd/docs/case1/CASESTUDY.md << 'EOF'
# Case Study 1: Example Project

This is an example case study for the GalleryMD system.

## Background

This demonstrates how case studies are displayed in the gallery.

## Results

- Successfully demonstrated case study display
- Showed markdown rendering capabilities
- Included associated image
EOF

cat > ~/gallerymd/docs/case2/CASESTUDY.md << 'EOF'
# Case Study 2: Another Example

This is another example case study.

## Overview

This shows how multiple case studies are organized in the gallery view.

## Key Features

1. Multiple case studies support
2. Organized gallery view
3. Detail view for each study
EOF

# Create README with instructions for adding more case studies
cat > ~/gallerymd/docs/README.md << 'EOF'
# GalleryMD Documentation

## How to Add Case Studies

1. Create a new subdirectory in the docs folder
2. Add a file named CASESTUDY.md in the subdirectory
3. Optionally add an image named CASESTUDY.jpg or CASESTUDY.png
4. Use the refresh API endpoint to trigger a rescan: curl -X POST http://localhost:3000/api/refresh

## Markdown Format

Your case study should start with a level 1 heading:

```
# Title of Case Study
```

This will be used as the title in the gallery.
EOF

# Set proper permissions
chown -R pewter:pewter ~/gallerymd

echo "Post-deployment configuration completed."
echo "You may now access the GalleryMD application at: http://$(hostname -I | awk '{print $1}'):3000"
