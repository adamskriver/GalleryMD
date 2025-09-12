
This document explains how to deploy the GalleryMD application to a virtual machine using the provided infrastructure scripts.

## Prerequisites


## Deployment Steps

### 1. Create the Cloud-Init Seed ISO

First, create the seed.iso file that will be used during Ubuntu installation:

```powershell
cd C:\Users\adam\OneDrive\Documents\GalleryMD\infrastructure
.\create-seed-iso.ps1
```

This will use Docker to generate a seed.iso file in the BWGalleryMD directory.

### 2. Create and Start the Virtual Machine

Run the VM creation script:

```powershell
cd C:\Users\adam\OneDrive\Documents\GalleryMD\infrastructure
.\create-vm-BWGalleryMD.ps1
```

Follow the on-screen instructions. The script will:

### 3. After Installation

Once Ubuntu is installed and running:

1. SSH into the VM:
   ```
   ssh pewter@<vm-ip-address>
   ```

2. The cloud-init configuration will automatically:
   - Install prerequisites (curl, git, unzip)
   - Install Deno
   - Create a systemd service for GalleryMD
   - Set up the basic directory structure

3. The GalleryMD application will be running on port 3000.
   Access it via http://<vm-ip-address>:3000

## Managing the Application


## Adding Content

Place your case study markdown files in the `/home/pewter/gallerymd/docs` directory:

## Notes


# Docker Deployment (Recommended)

You can run GalleryMD as a background service on your Windows machine using Docker:

```sh
docker run -d --restart unless-stopped -p 3003:3003 -v "C:\Users\adam\OneDrive\Documents:/app/docs" gallerymd
```

This will keep the container running even after you close the terminal, and your Documents folder will be available to the app inside the container.

---
