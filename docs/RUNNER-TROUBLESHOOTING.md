# GitHub Actions Runner Troubleshooting Guide

## Common Issues and Solutions

### 1. Runner Fails After Short Time

**Symptoms:**

- Runner container constantly restarting
- Logs show "Not configured" or "404 Not Found"
- Runner disappears from GitHub settings

**Cause:** Registration token expired (tokens only last 1 hour)

**Solution:** Use Personal Access Token (PAT) authentication instead:

```powershell
# Set your GitHub PAT (create one with 'repo' scope)
$env:GITHUB_PAT = "ghp_your_personal_access_token"

# Start runner with PAT authentication
.\scripts\start-runner-pat.ps1 -StopFirst
```

### 2. How to Create a GitHub Personal Access Token

1. Go to: <https://github.com/settings/tokens/new>
2. Give it a descriptive name: "GalleryMD Runner"
3. Select scope: `repo` (Full control of private repositories)
4. Set expiration: 90 days or more (longer is better)
5. Click "Generate token"
6. Copy the token immediately (you won't see it again)

### 3. Quick Health Check

```powershell
# Check runner health
.\scripts\check-runner-health.ps1

# With GitHub API check (requires PAT)
$env:GITHUB_PAT = "your_pat"
.\scripts\check-runner-health.ps1 -Detailed
```

### 4. Monitoring Runner Logs

```powershell
# Live logs
docker compose logs -f runner

# Last 100 lines
docker logs gallerymd-runner --tail=100

# Search for errors
docker logs gallerymd-runner 2>&1 | Select-String "error|fail"
```

### 5. Manual Recovery Steps

If the runner is completely broken:

```powershell
# 1. Stop and remove the container
docker compose down runner
docker rm -f gallerymd-runner

# 2. Remove runner from GitHub (if stuck)
# Go to: https://github.com/adamskriver/GalleryMD/settings/actions/runners
# Click on the runner and remove it

# 3. Clean up volumes (if needed)
docker volume rm gallerymd_runner_work gallerymd_runner_config

# 4. Start fresh with PAT
$env:GITHUB_PAT = "your_pat"
.\scripts\start-runner-pat.ps1
```

### 6. Preventing Future Failures

**Best Practices:**

1. **Always use PAT authentication** instead of registration tokens
2. **Set PAT expiration to 90+ days** and calendar reminder to renew
3. **Monitor runner health** regularly:

   ```powershell
   # Add to your daily routine
   .\scripts\check-runner-health.ps1
   ```

4. **Persist runner configuration** using volumes (already configured)

5. **Set up alerts** for runner failures (optional):
   - GitHub webhook for workflow failures
   - Docker health checks
   - Log monitoring

### 7. Environment Variables Reference

```powershell
# Required
$env:GITHUB_PAT = "ghp_..."  # Personal Access Token with 'repo' scope

# Optional (defaults shown)
$env:REPO = "adamskriver/GalleryMD"
$env:RUNNER_NAME = "gallerymd-runner"
$env:LABELS = "self-hosted,docker,linux"
$env:RUNNER_WORKDIR = "/tmp/runner"
$env:RUNNER_SCOPE = "repo"
```

### 8. Debugging Commands

```powershell
# Check container status
docker ps -a | Select-String "runner"

# Inspect container
docker inspect gallerymd-runner | ConvertFrom-Json

# Check volumes
docker volume ls | Select-String "runner"

# Test GitHub API connection
$headers = @{Authorization = "token $env:GITHUB_PAT"}
Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
```

## Architecture Notes

The runner uses the `myoung34/github-runner` Docker image which:

- Automatically registers/unregisters the runner
- Supports both TOKEN and PAT authentication
- Handles runner updates (we disable auto-update)
- Provides Docker-in-Docker capability

## Security Considerations

1. **PAT Storage**: Never commit PATs to git. Use environment variables or secrets
2. **Scope Limitation**: PAT only needs 'repo' scope for runners
3. **Token Rotation**: Set calendar reminders to rotate PATs before expiry
4. **Network Isolation**: Runner uses dedicated Docker network
5. **Volume Permissions**: Runner volumes are isolated from host

## Need Help?

1. Check runner health: `.\scripts\check-runner-health.ps1`
2. Read the logs: `docker logs gallerymd-runner --tail=100`
3. Verify on GitHub: <https://github.com/adamskriver/GalleryMD/settings/actions/runners>
4. File an issue with full error logs