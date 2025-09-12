# Destroy BWGalleryMD Virtual Machine Script
# This script removes the VM and deletes associated files

# Variables
$VMName = "BWGalleryMD"
$VMPath = "C:\HyperV\BWGalleryMD"
$VHDPath = "$VMPath\BWGalleryMD.vhdx"

Write-Host "🔥 Destroying $VMName VM..." -ForegroundColor Red
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "VM Path: $VMPath" -ForegroundColor Cyan

# Validate prerequisites
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -ne 'Enabled') {
    Write-Error "Hyper-V is not enabled. Cannot manage VMs."
    exit 1
}

# Check if VM exists
$VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $VM) {
    Write-Warning "VM '$VMName' does not exist."
    
    # Check if VM directory exists and offer to clean it up
    if (Test-Path $VMPath) {
        Write-Warning "VM directory '$VMPath' exists but VM is not registered."
        Write-Host "Do you want to delete the VM directory anyway? (y/N)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "Deleting VM directory..." -ForegroundColor Yellow
            Remove-Item $VMPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $VMPath)) {
                Write-Host "✅ VM directory deleted successfully." -ForegroundColor Green
            } else {
                Write-Error "Failed to delete VM directory."
            }
        }
    }
    exit 0
}

# Display VM information before deletion
Write-Host ""
Write-Host "Current VM Details:" -ForegroundColor Yellow
Write-Host "  Name: $($VM.Name)"
Write-Host "  State: $($VM.State)"
Write-Host "  Path: $($VM.Path)"
Write-Host "  Memory: $([math]::Round($VM.MemoryStartup / 1GB, 2))GB"
if ($VM.HardDrives) {
    Write-Host "  Hard Drives:"
    foreach ($drive in $VM.HardDrives) {
        Write-Host "    - $($drive.Path)"
    }
}

Write-Host ""
Write-Host "⚠️  WARNING: This will permanently delete the VM and all associated files!" -ForegroundColor Red
Write-Host "Do you want to continue? (y/N)" -ForegroundColor Yellow
$confirmResponse = Read-Host

if ($confirmResponse -ne 'y' -and $confirmResponse -ne 'Y') {
    Write-Host "Operation cancelled." -ForegroundColor Green
    exit 0
}

try {
    # Stop the VM if it's running
    if ($VM.State -eq 'Running') {
        Write-Host "Stopping VM..." -ForegroundColor Yellow
        Stop-VM -Name $VMName -Force
        Write-Host "✅ VM stopped." -ForegroundColor Green
    }

    # Remove the VM
    Write-Host "Removing VM from Hyper-V..." -ForegroundColor Yellow
    Remove-VM -Name $VMName -Force
    Write-Host "✅ VM removed from Hyper-V." -ForegroundColor Green

    # Delete VM directory and files
    if (Test-Path $VMPath) {
        Write-Host "Deleting VM directory and files..." -ForegroundColor Yellow
        Remove-Item $VMPath -Recurse -Force
        
        # Verify deletion
        if (-not (Test-Path $VMPath)) {
            Write-Host "✅ VM directory deleted successfully." -ForegroundColor Green
        } else {
            Write-Error "Failed to completely delete VM directory. Some files may remain."
        }
    }

    # Clean up any orphaned checkpoint files
    $CheckpointPath = "C:\HyperV\BWGalleryMD\Snapshots"
    if (Test-Path $CheckpointPath) {
        Write-Host "Cleaning up checkpoint files..." -ForegroundColor Yellow
        Remove-Item $CheckpointPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "🎉 VM '$VMName' has been completely destroyed!" -ForegroundColor Green
    Write-Host "All associated files have been deleted." -ForegroundColor Green

} catch {
    Write-Error "An error occurred while destroying the VM: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Manual cleanup may be required:" -ForegroundColor Yellow
    Write-Host "1. Check Hyper-V Manager for any remaining VM entries" -ForegroundColor Yellow
    Write-Host "2. Manually delete directory: $VMPath" -ForegroundColor Yellow
    exit 1
}

# Optional: Clean up base HyperV directory if it's empty
$BaseVMDir = "C:\HyperV"
if (Test-Path $BaseVMDir) {
    $remainingItems = Get-ChildItem $BaseVMDir -ErrorAction SilentlyContinue
    if (-not $remainingItems) {
        Write-Host "Base HyperV directory is empty. Delete it? (y/N)" -ForegroundColor Yellow
        $cleanupResponse = Read-Host
        if ($cleanupResponse -eq 'y' -or $cleanupResponse -eq 'Y') {
            Remove-Item $BaseVMDir -Force
            Write-Host "✅ Base HyperV directory deleted." -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Destruction complete! You can now create a new VM if needed." -ForegroundColor Cyan
