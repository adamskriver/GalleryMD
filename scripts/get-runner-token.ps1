# Fetch a GitHub Actions runner registration token and write .env
param(
  [string]$Repo = $env:REPO,     # format: owner/repo (e.g., adamskriver/GalleryMD)
  [string]$Pat  = $env:GH_PAT    # GitHub PAT with repo scope
)

if (-not $Repo) { 
  Write-Error "REPO not set. Set environment variable or pass -Repo 'owner/repo'."
  exit 1 
}
if (-not $Pat) { 
  Write-Error "GH_PAT not set. Set environment variable with your GitHub PAT."
  exit 1 
}

$api = "https://api.github.com/repos/$Repo/actions/runners/registration-token"
$headers = @{ 
  Authorization = "token $Pat"
  "User-Agent" = "gh-runner-helper"
  Accept = "application/vnd.github+json"
}

Write-Output "Requesting registration token from GitHub API..."
try {
  $res = Invoke-RestMethod -Method Post -Uri $api -Headers $headers -ContentType 'application/json'
} catch {
  Write-Error "Failed to get registration token: $($_.Exception.Message)"
  Write-Error "Check that your PAT has 'repo' scope and the repo name is correct."
  exit 1
}

$token = $res.token
if (-not $token) { 
  Write-Error "No token returned from API."
  exit 1 
}

# Write .env file
$envLines = @(
  "REPO=$Repo"
  "RUNNER_NAME=gallerymd-runner"
  "LABELS=self-hosted,docker,windows"
  "RUNNER_WORKDIR=/tmp/runner"
  "RUNNER_TOKEN=$token"
  "RUNNER_SCOPE=repo"
)
$envPath = Join-Path $PSScriptRoot ".." ".env"
$envLines -join "`n" | Set-Content -Path $envPath -Encoding UTF8

Write-Output ""
Write-Output "✓ Created .env with registration token (expires in 1 hour)"
Write-Output "✓ Start the runner with: docker-compose -f docker-compose.runner.yml up -d"
Write-Output ""
Write-Output "Security note: The .env file contains a registration token."
Write-Output "After the runner registers successfully, you can delete .env if desired."
