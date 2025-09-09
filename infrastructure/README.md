# Deploy GalleryMD Application to VM

This document explains how to deploy the GalleryMD application to a virtual machine using the provided infrastructure scripts.

## Prerequisites

- Windows with Hyper-V enabled
- Docker installed (for creating the seed.iso)
- Ubuntu Server ISO downloaded
- A configured Hyper-V virtual switch

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
- Create a new VM named "BWGalleryMD" with 1GB RAM and 5GB disk
- Attach the Ubuntu ISO and cloud-init seed.iso
- Configure network settings
- Guide you through the installation process

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

- Start the service: `sudo systemctl start gallerymd.service`
- Stop the service: `sudo systemctl stop gallerymd.service`
- Restart the service: `sudo systemctl restart gallerymd.service`
- Check status: `sudo systemctl status gallerymd.service`
- View logs: `sudo journalctl -u gallerymd.service`

## Adding Content

Place your case study markdown files in the `/home/pewter/gallerymd/docs` directory:
- Files should be named `CASESTUDY.md`
- Associated images should be named `CASESTUDY.png`, `CASESTUDY.jpg`, etc.
- Organize case studies in subdirectories for better organization

## Notes

- The VM is configured to use 1GB RAM which is minimal. Increase if needed.
- The 5GB disk size is also minimal; increase for production use.
- The application uses unencrypted HTTP. For production, consider adding HTTPS.
