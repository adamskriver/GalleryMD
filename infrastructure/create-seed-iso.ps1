# Create seed.iso using Genisoimage Docker container

# This script generates a seed.iso file for cloud-init from user-data and meta-data files
# Run this script from the infrastructure directory

# Default paths
$UserDataPath = ".\BWGalleryMD\user-data"
$MetaDataPath = ".\BWGalleryMD\meta-data"
$OutputPath = ".\BWGalleryMD\seed.iso"

# Verify files exist
if (-not (Test-Path $UserDataPath)) {
    Write-Error "user-data file not found at $UserDataPath"
    exit 1
}

if (-not (Test-Path $MetaDataPath)) {
    Write-Error "meta-data file not found at $MetaDataPath"
    exit 1
}

Write-Host "Creating seed.iso from cloud-init files..." -ForegroundColor Green

# Get absolute paths for Docker volume mapping
$CurrentDir = (Get-Location).Path
$SeedDir = "$CurrentDir\BWGalleryMD"
$DockerVolumePath = $SeedDir -replace "\\", "/"
$DockerVolumePath = $DockerVolumePath -replace ":", ""
$DockerVolumePath = "/$DockerVolumePath"

# Run genisoimage in Docker to create the seed.iso
Write-Host "Running genisoimage via Docker..." -ForegroundColor Yellow
Write-Host "Source directory: $SeedDir" -ForegroundColor Cyan 
Write-Host "Docker path: $DockerVolumePath" -ForegroundColor Cyan

docker run --rm -v "${SeedDir}:${DockerVolumePath}" jrei/systemd-ubuntu:20.04 bash -c "apt-get update && apt-get install -y genisoimage && genisoimage -output ${DockerVolumePath}/seed.iso -volid CIDATA -joliet -rock ${DockerVolumePath}/user-data ${DockerVolumePath}/meta-data"

if ($LASTEXITCODE -eq 0) {
    Write-Host "seed.iso created successfully at $OutputPath" -ForegroundColor Green
} else {
    Write-Error "Failed to create seed.iso"
    exit 1
}

# Verify file was created
if (Test-Path $OutputPath) {
    $fileSize = (Get-Item $OutputPath).Length
    Write-Host "seed.iso file size: $($fileSize) bytes" -ForegroundColor Cyan
} else {
    Write-Error "seed.iso was not created at $OutputPath"
    exit 1
}
