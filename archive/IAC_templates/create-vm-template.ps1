# TEMPLATE: Virtual Machine Creation Script for Ubuntu on Hyper-V
# Replace variables as needed for your project
# Requires: Windows with Hyper-V, Ubuntu Server 24.04+ ISO
# LESSONS LEARNED: This template captures Ubuntu/Hyper-V deployment challenges

# Variables
$VMName    = "<VM_NAME>"
$VMPath    = "C:\\HyperV\\$VMName"
$VHDPath   = "$VMPath\\$VMName.vhdx"
$ISOPath   = "<PATH_TO_UBUNTU_ISO>" # Update this path
$SeedISO   = "$PSScriptRoot\\<SEED_DIR>\\seed.iso" # Update as needed
$Switch    = "<VIRTUAL_SWITCH>"
$MemoryGB  = <MEMORY_GB>
$DiskSizeGB = <DISK_SIZE_GB>

# Configuration
$Memory = $MemoryGB * 1GB
$DiskSize = $DiskSizeGB * 1GB

Write-Host "Starting $VMName VM Creation..." -ForegroundColor Green
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "Memory: ${MemoryGB}GB" -ForegroundColor Cyan
Write-Host "Disk: ${DiskSizeGB}GB" -ForegroundColor Cyan

# Validate prerequisites
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -ne 'Enabled') {
    Write-Error "Hyper-V is not enabled. Please enable Hyper-V and restart."
    exit 1
}

# Check for seed.iso
if (-not (Test-Path $SeedISO)) {
    Write-Error "Seed ISO file not found at: $SeedISO"
    Write-Host "Please run create-seed-iso.ps1 first to create the seed.iso" -ForegroundColor Yellow
    exit 1
}

# Check for Ubuntu ISO
if (-not (Test-Path $ISOPath)) {
    Write-Error "Ubuntu ISO not found at: $ISOPath"
    Write-Host "Please update the script with the correct path to Ubuntu ISO" -ForegroundColor Yellow
    exit 1
}

# Create base VM directory
$BaseVMDir = "C:\\HyperV"
if (-not (Test-Path $BaseVMDir)) {
    New-Item -ItemType Directory -Path $BaseVMDir -Force
    Write-Host "Created VM directory: $BaseVMDir" -ForegroundColor Yellow
}

# Handle VM-specific directory
if (Test-Path $VMPath) {
    Write-Warning "VM directory '$VMPath' already exists. Do you want to delete it and continue? (y/N)"
    $dirResponse = Read-Host
    if ($dirResponse -eq 'y' -or $dirResponse -eq 'Y') {
        Remove-Item $VMPath -Recurse -Force
        Write-Host "Deleted VM directory: $VMPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $VMPath -Force
    } else {
        Write-Host "Exiting without changes." -ForegroundColor Red
        exit 0
    }
} else {
    New-Item -ItemType Directory -Path $VMPath -Force
}

# Check if VM already exists
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
    Write-Warning "VM '$VMName' already exists. Do you want to remove it and recreate? (y/N)"
    $response = Read-Host
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "Removing existing VM..." -ForegroundColor Yellow
        Stop-VM -Name $VMName -Force -ErrorAction SilentlyContinue
        Remove-VM -Name $VMName -Force
        if (Test-Path $VHDPath) {
            Remove-Item $VHDPath -Force
        }
    } else {
        Write-Host "Exiting without changes." -ForegroundColor Red
        exit 0
    }
}

# Create virtual hard disk
Write-Host "Creating virtual hard disk..." -ForegroundColor Yellow
New-VHD -Path $VHDPath -SizeBytes $DiskSize -Dynamic

# Create virtual machine
Write-Host "Creating virtual machine..." -ForegroundColor Yellow
$VM = New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes $Memory -VHDPath $VHDPath -Generation 2

# Configure VM settings
Write-Host "Configuring VM settings..." -ForegroundColor Yellow

# Set memory
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 1GB -MaximumBytes $Memory -StartupBytes $Memory

# Set processor count
Set-VMProcessor -VMName $VMName -Count <CPU_COUNT>

# Enable nested virtualization (optional)
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true

# Configure network adapter
if (Get-VMSwitch -Name $Switch -ErrorAction SilentlyContinue) {
    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $Switch
    Write-Host "Connected to switch: $Switch" -ForegroundColor Green
} else {
    Write-Warning "Switch '$Switch' not found. VM will have no network connectivity."
    Write-Host "Available switches:" -ForegroundColor Cyan
    Get-VMSwitch | Format-Table Name, SwitchType
}

# Disable secure boot for Linux compatibility
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

# Add Ubuntu ISO as DVD drive
$ubuntuDVD = Add-VMDvdDrive -VMName $VMName -Path $ISOPath -Passthru

# Check if seed.iso exists in the seed directory
$seedIsoPath = Join-Path $PSScriptRoot "<SEED_DIR>\\seed.iso"
if (Test-Path $seedIsoPath) {
    Add-VMDvdDrive -VMName $VMName -Path $seedIsoPath
    Write-Host "Attached cloud-init seed.iso to the VM."
} else {
    Write-Warning "No seed.iso found in <SEED_DIR> directory."
    Write-Host "Please run create-seed-isos.ps1 first to create seed.iso files." -ForegroundColor Yellow
    $continue = Read-Host "Do you want to continue without the seed.iso? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Error "Exiting. Please create seed.iso first."
        exit 1
    }
}

# Set boot order: First boot from Ubuntu ISO
Set-VMFirmware -VMName $VMName -FirstBootDevice $ubuntuDVD

# Display instructions before starting VM
Write-Host ""
Write-Host "VM is ready to start. Ubuntu installation will begin." -ForegroundColor Green
Write-Host ""
Write-Host "CRITICAL FOR UBUNTU AUTOINSTALL ON HYPER-V:" -ForegroundColor Red
Write-Host "You may need to manually add boot parameters if autoinstall doesn't trigger:" -ForegroundColor Yellow
Write-Host "1. At the GRUB menu, press 'e' to edit boot options" -ForegroundColor Yellow
Write-Host "2. Find the line starting with 'linux' and add to the end:" -ForegroundColor Yellow
Write-Host "   autoinstall ds=nocloud;s=/cdrom/ quiet" -ForegroundColor Cyan
Write-Host "3. Press F10 to boot with these parameters" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: Installation is fully automated with cloud-init seed.iso" -ForegroundColor Green
Write-Host "The VM should install Ubuntu without any user interaction." -ForegroundColor Green
Write-Host ""
Write-Host "Start the VM now? (y/N)" -ForegroundColor Green
$startResponse = Read-Host
if ($startResponse -eq 'y' -or $startResponse -eq 'Y') {
    # Start VM
    Start-VM -Name $VMName
    Write-Host "VM started. Opening connection..." -ForegroundColor Green
    Start-Process -FilePath "vmconnect.exe" -ArgumentList "localhost", $VMName
} else {
    Write-Host "VM created but not started. To start it manually, use:" -ForegroundColor Yellow
    Write-Host "Start-VM -Name $VMName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "VM Details:" -ForegroundColor Yellow
Write-Host "  Name: $VMName"
Write-Host "  Path: $VMPath"
Write-Host "  Disk: $VHDPath"
Write-Host "  Memory: ${MemoryGB}GB"
Write-Host "  Network: $Switch"
$VM = Get-VM -Name $VMName
Write-Host "  VM State: $($VM.State)"
