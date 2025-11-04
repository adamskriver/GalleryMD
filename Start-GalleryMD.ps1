# GalleryMD - Get Fresh Runner Token and Start Services
# This script fetches a new runner token from GitHub and starts all services

Write-Host "🔧 GalleryMD Setup - Getting fresh runner token..." -ForegroundColor Cyan

# Check if gh is available
try {
    $null = gh --version
} catch {
    Write-Host "❌ GitHub CLI (gh) is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   winget install --id GitHub.cli" -ForegroundColor Yellow
    exit 1
}

# Get repository from .env
$repo = (Get-Content .env | Select-String "^REPO=").Line.Split('=')[1]
Write-Host "📦 Repository: $repo" -ForegroundColor Green

# Get a fresh runner registration token
Write-Host "🔑 Fetching runner registration token from GitHub..." -ForegroundColor Cyan
try {
    $tokenJson = gh api --method POST `
                        -H "Accept: application/vnd.github+json" `
                        -H "X-GitHub-Api-Version: 2022-11-28" `
                        "repos/$repo/actions/runners/registration-token"
    
    $token = ($tokenJson | ConvertFrom-Json).token
    
    if (-not $token) {
        throw "No token received from GitHub"
    }
    
    Write-Host "✅ Runner token received (expires in 1 hour)" -ForegroundColor Green
    
    # Update .env file with fresh token
    $envContent = Get-Content .env
    $envContent = $envContent -replace '^RUNNER_TOKEN=.*', "RUNNER_TOKEN=$token"
    $envContent | Set-Content .env
    
    Write-Host "✅ Updated .env with fresh runner token" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to get runner token: $_" -ForegroundColor Red
    Write-Host "   Make sure you have admin access to the repository" -ForegroundColor Yellow
    exit 1
}

# Stop existing containers
Write-Host "`n🛑 Stopping existing containers..." -ForegroundColor Cyan

# Force remove old standalone containers if they exist
docker stop gallerymd 2>$null
docker rm gallerymd 2>$null
docker stop gallerymd-runner 2>$null
docker rm gallerymd-runner 2>$null

# Stop compose services
docker compose down 2>$null

# Start all services
Write-Host "`n🚀 Starting GalleryMD and runner..." -ForegroundColor Cyan
docker compose up -d

# Wait a moment for containers to start
Start-Sleep -Seconds 3

# Show status
Write-Host "`n📊 Container Status:" -ForegroundColor Cyan
docker compose ps

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
Write-Host "   • Check runner status on GitHub: https://github.com/$repo/settings/actions/runners" -ForegroundColor Yellow
Write-Host "   • View logs: docker compose logs -f" -ForegroundColor Yellow
Write-Host "   • Test app: http://localhost:3003" -ForegroundColor Yellow
