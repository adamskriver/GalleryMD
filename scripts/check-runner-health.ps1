# Check GitHub Actions Runner Health
param(
    [string]$Repo = "adamskriver/GalleryMD",
    [string]$Pat = $env:GITHUB_PAT,
    [switch]$Detailed
)

Write-Host "=== GitHub Actions Runner Health Check ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker container status
Write-Host "Docker Container Status:" -ForegroundColor Yellow
$containerStatus = docker ps --filter "name=runner" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
if ($containerStatus) {
    Write-Host $containerStatus
} else {
    Write-Host "No runner container found!" -ForegroundColor Red
}

Write-Host ""

# Check recent logs
Write-Host "Recent Logs (last 10 lines):" -ForegroundColor Yellow
docker logs --tail=10 gallerymd-runner 2>&1 | ForEach-Object {
    if ($_ -match "error|fail|denied") {
        Write-Host $_ -ForegroundColor Red
    } elseif ($_ -match "Listening for Jobs|Running job") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_
    }
}

Write-Host ""

# Check GitHub API for runner status (if PAT provided)
if ($Pat) {
    Write-Host "GitHub Runner Registration Status:" -ForegroundColor Yellow
    $headers = @{
        Authorization = "token $Pat"
        Accept = "application/vnd.github+json"
    }
    
    try {
        $runners = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/actions/runners" -Headers $headers
        $selfHosted = $runners.runners | Where-Object { $_.labels.name -contains "self-hosted" }
        
        if ($selfHosted) {
            foreach ($runner in $selfHosted) {
                $status = if ($runner.status -eq "online") { "✓ ONLINE" } else { "✗ OFFLINE" }
                $statusColor = if ($runner.status -eq "online") { "Green" } else { "Red" }
                Write-Host "$status - $($runner.name) (ID: $($runner.id))" -ForegroundColor $statusColor
                if ($Detailed) {
                    Write-Host "  OS: $($runner.os)"
                    Write-Host "  Labels: $($runner.labels.name -join ', ')"
                    Write-Host "  Busy: $($runner.busy)"
                }
            }
        } else {
            Write-Host "No self-hosted runners found!" -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to check GitHub API: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Set GITHUB_PAT to check runner registration status on GitHub" -ForegroundColor Gray
}

Write-Host ""

# Provide recommendations
Write-Host "Recommendations:" -ForegroundColor Yellow
$logs = docker logs --tail=50 gallerymd-runner 2>&1

if ($logs -match "Not configured|404.*Not Found") {
    Write-Host "• Runner is not properly registered. Token may be expired." -ForegroundColor Red
    Write-Host "• Solution: Use a Personal Access Token (PAT) instead of registration token" -ForegroundColor Green
    Write-Host "• Run: .\scripts\start-runner-pat.ps1 -StopFirst" -ForegroundColor Green
} elseif ($logs -match "Listening for Jobs") {
    Write-Host "✓ Runner is healthy and listening for jobs!" -ForegroundColor Green
} elseif ($logs -match "Running job") {
    Write-Host "✓ Runner is currently executing a job!" -ForegroundColor Green
} else {
    Write-Host "• Runner status unclear. Check detailed logs with:" -ForegroundColor Yellow
    Write-Host "  docker logs gallerymd-runner --tail=100" -ForegroundColor Gray
}

Write-Host ""