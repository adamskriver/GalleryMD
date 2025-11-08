# Start GitHub Actions runner with Personal Access Token
param(
    [string]$Repo = "adamskriver/GalleryMD",
    [string]$Pat = $env:GITHUB_PAT,
    [switch]$StopFirst
)

if (-not $Pat) {
    Write-Error "GITHUB_PAT not set. Please set your GitHub Personal Access Token with 'repo' scope."
    Write-Host ""
    Write-Host "To create a PAT:"
    Write-Host "1. Go to: https://github.com/settings/tokens/new"
    Write-Host "2. Select scope: 'repo' (Full control of private repositories)"
    Write-Host "3. Set expiration (recommend 90 days or more)"
    Write-Host "4. Generate token and save it"
    Write-Host ""
    Write-Host "Then run: `$env:GITHUB_PAT = 'your_pat_token'"
    exit 1
}

# Stop existing runner if requested
if ($StopFirst) {
    Write-Host "Stopping existing runner..."
    docker compose down runner
    docker rm -f gallerymd-runner gallerymd-runner-pat 2>$null
    Start-Sleep -Seconds 2
}

# Create .env file with PAT configuration
$envContent = @"
REPO=$Repo
GITHUB_PAT=$Pat
RUNNER_NAME=gallerymd-runner-pat
LABELS=self-hosted,docker,linux
RUNNER_WORKDIR=/tmp/runner
RUNNER_SCOPE=repo
"@

$envPath = Join-Path $PSScriptRoot ".." ".env"
$envContent | Set-Content -Path $envPath -Encoding UTF8

Write-Host "✓ Created .env with PAT configuration"
Write-Host ""

# Start the runner with PAT authentication
Write-Host "Starting GitHub Actions runner with PAT authentication..."
docker compose -f docker-compose.runner-pat.yml up -d

Start-Sleep -Seconds 5

# Check status
Write-Host ""
Write-Host "Checking runner status..."
docker compose -f docker-compose.runner-pat.yml ps
docker compose -f docker-compose.runner-pat.yml logs --tail=20

Write-Host ""
Write-Host "✓ Runner started with PAT authentication"
Write-Host "✓ This configuration is more stable and doesn't expire"
Write-Host ""
Write-Host "To monitor: docker compose -f docker-compose.runner-pat.yml logs -f"