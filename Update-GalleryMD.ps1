# Update-GalleryMD.ps1
# This script updates the GalleryMD Docker container with the latest image from Docker Hub

# Configuration
$dockerImage = "adamskriver/gallerymd:latest"  # Replace with your Docker Hub username
$containerName = "gallerymd"
$port = 3000
$localDocsPath = "C:/Users/adam/OneDrive/Documents"  # Update this with your local path
$containerDocsPath = "/docs"

Write-Host "Updating GalleryMD container with latest image..." -ForegroundColor Cyan

# Pull the latest image
Write-Host "Pulling latest image: $dockerImage" -ForegroundColor Yellow
docker pull $dockerImage

# Check if container is already running
$containerRunning = docker ps --filter "name=$containerName" --format "{{.Names}}"

if ($containerRunning) {
    # Stop and remove the existing container
    Write-Host "Stopping existing container: $containerName" -ForegroundColor Yellow
    docker stop $containerName
    docker rm $containerName
}

# Start a new container with the latest image
Write-Host "Starting new container with the latest image" -ForegroundColor Yellow
docker run -d --name $containerName `
    -p ${port}:3000 `
    -v "${localDocsPath}:${containerDocsPath}" `
    -e MD_ROOT=$containerDocsPath `
    --restart unless-stopped `
    $dockerImage

Write-Host "Container updated successfully!" -ForegroundColor Green
Write-Host "GalleryMD is running at http://localhost:$port" -ForegroundColor Cyan