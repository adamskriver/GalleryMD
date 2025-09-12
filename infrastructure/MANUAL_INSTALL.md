# BWGalleryMD VM Installation Guide - Alternative Approach

Due to issues with the automated cloud-init installation, here is a simplified approach:

## Step 1: Create a Minimal VM

Run the provided `create-vm-BWGalleryMD.ps1` script. When you reach the Ubuntu installer:

1. Select "Install Ubuntu Server"
2. Follow the basic installation prompts:
   - Language: English
   - Layout: US
   - Network: DHCP (automatic)
   - Proxy: None
   - Mirror: Default
   - Storage: Use entire disk, no LVM
   - Profile setup:
     - Your name: Pewter User
     - Server name: bwgallerymd
     - Username: pewter
     - Password: (use your password)
   - SSH: Install OpenSSH server (select with Space)
   - Featured snaps: None (continue)

## Step 2: Post-Installation Setup

After the VM reboots and Ubuntu is running:

1. Find the VM's IP address:
   - Log in to the VM
   - Run `ip addr show`
   - Look for the IPv4 address on interface 'eth0' (typically 192.168.x.x or 10.x.x.x)

2. From your Windows machine, run the post-install script:
   ```powershell
   cd C:\Users\adam\OneDrive\Documents\GalleryMD\infrastructure
   Get-Content post-install.sh | ssh pewter@VM_IP "bash -s"
   ```
   (Replace VM_IP with the actual IP address)

3. Copy the server.ts file:
   ```powershell
   scp C:\Users\adam\OneDrive\Documents\GalleryMD\server.ts pewter@VM_IP:~/gallerymd/
   ```

4. Start the GalleryMD service:
   ```powershell
   ssh pewter@VM_IP "sudo systemctl start gallerymd.service"
   ```

5. Verify the service is running:
   ```powershell
   ssh pewter@VM_IP "sudo systemctl status gallerymd.service"
   ```

6. Access the application at http://VM_IP:3000

## Troubleshooting

If you encounter issues:

1. Check logs:
   ```
   sudo journalctl -u gallerymd.service
   ```

2. Verify Deno is installed:
   ```
   ~/.deno/bin/deno --version
   ```

3. Manually start the server to see direct output:
   ```
   cd ~/gallerymd
   ~/.deno/bin/deno run --allow-net --allow-read --allow-env server.ts
   ```
