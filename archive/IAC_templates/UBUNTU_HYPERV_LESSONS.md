# Ubuntu on Hyper-V Deployment Lessons Learned

This document captures critical lessons learned from deploying Ubuntu VMs on Hyper-V, specifically issues encountered and their solutions.

## Critical Issues and Solutions

### 1. **Autoinstall Configuration**
**Problem**: Ubuntu installation stops for user interaction, making automation impossible.

**Solution**: Use the full `autoinstall` configuration in `user-data`:
```yaml
autoinstall:
  version: 1
  interactive-sections: []  # CRITICAL: Skip all interactive steps
```

### 2. **Package Installation Prompts**
**Problem**: Package installations stop for debconf prompts during setup.

**Solution**: Set non-interactive mode in both `early-commands` and `late-commands`:
```yaml
early-commands:
  - echo 'debconf debconf/frontend select noninteractive' | debconf-set-selections
late-commands:
  - echo 'debconf debconf/frontend select noninteractive' | chroot /target debconf-set-selections
```

### 3. **Boot Parameter Issues**
**Problem**: Cloud-init autoinstall doesn't trigger automatically on some Ubuntu ISO versions.

**Solution**: Manually add boot parameters at GRUB:
- Press 'e' at GRUB menu
- Add to linux line: `autoinstall ds=nocloud;s=/cdrom/ quiet`
- Press F10 to boot

### 4. **Storage Configuration**
**Problem**: Ubuntu installer hangs on storage configuration.

**Solution**: Explicitly specify storage layout:
```yaml
storage:
  layout:
    name: direct
```

### 5. **Network Configuration for Hyper-V**
**Problem**: Network interfaces not properly configured for Hyper-V DHCP.

**Solution**: Use netplan v2 configuration:
```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
```

### 6. **Secure Boot Compatibility**
**Problem**: Linux VMs fail to boot with Secure Boot enabled.

**Solution**: Disable Secure Boot in PowerShell script:
```powershell
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
```

### 7. **Generation 2 VM Requirements**
**Problem**: Need UEFI boot for modern Ubuntu versions.

**Solution**: Always use Generation 2 VMs:
```powershell
$VM = New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes $Memory -VHDPath $VHDPath -Generation 2
```

### 8. **Cloud-Init Seed ISO Issues**
**Problem**: Cloud-init doesn't find configuration data.

**Solution**: 
- Ensure `seed.iso` contains both `user-data` and `meta-data`
- Attach as second DVD drive
- Use proper cloud-init directory structure

### 9. **Dynamic Memory Issues**
**Problem**: VMs with too little memory fail during installation.

**Solution**: Set appropriate memory limits:
```powershell
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 1GB -MaximumBytes $Memory -StartupBytes $Memory
```

### 10. **SSH Key Configuration**
**Problem**: SSH keys not properly deployed during installation.

**Solution**: Use both password and key authentication in autoinstall:
```yaml
ssh:
  install-server: true
  allow-pw: true  # Allow password auth as backup
  ssh_authorized_keys:
    - <SSH_KEY>
```

## Best Practices Summary

1. **Always use `autoinstall`** for unattended installation
2. **Set non-interactive mode** in both early and late commands
3. **Disable Secure Boot** for Linux VMs
4. **Use Generation 2 VMs** for UEFI support
5. **Explicitly configure storage** to avoid hanging
6. **Test SSH access** immediately after installation
7. **Include fallback authentication** (password + keys)
8. **Monitor installation logs** via Hyper-V console
9. **Keep seed.iso structure correct** (user-data + meta-data)
10. **Set proper boot order** (Ubuntu ISO first, then seed.iso)

## Troubleshooting Commands

```bash
# Check cloud-init status
cloud-init status

# View cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Check if SSH service is running
sudo systemctl status ssh

# Test network connectivity
ping 8.8.8.8

# Check disk space
df -h
```

## Password Hash Generation

Generate password hashes for user-data:
```bash
# Method 1: Using openssl
openssl passwd -6 -salt $(openssl rand -base64 16) yourpassword

# Method 2: Using python3
python3 -c 'import crypt; print(crypt.crypt("yourpassword", crypt.mksalt(crypt.METHOD_SHA512)))'
```

## VM Creation Checklist

- [ ] Hyper-V enabled and running
- [ ] Ubuntu 24.04+ ISO downloaded
- [ ] Virtual switch created and accessible
- [ ] `user-data` configured with autoinstall
- [ ] `meta-data` has unique instance-id
- [ ] `seed.iso` created and accessible
- [ ] VM name and paths are unique
- [ ] Network switch exists
- [ ] Secure Boot disabled for Linux
- [ ] Boot order set correctly (Ubuntu ISO first)
- [ ] Memory and CPU allocated appropriately

## File Structure

```
infrastructure/
├── create-vm-script.ps1          # VM creation script
├── VM_NAME/                      # VM-specific directory
│   ├── user-data                 # Cloud-init configuration
│   ├── meta-data                 # VM metadata
│   └── seed.iso                  # Cloud-init ISO
```

This template captures all the hard-learned lessons from Ubuntu/Hyper-V deployment challenges.
