# Self-Hosted GitHub Actions Runner in Docker

This guide sets up a self-hosted GitHub Actions runner for the GalleryMD repository using Docker.

## Prerequisites

- Docker Desktop installed and running
- PowerShell (Windows PowerShell or PowerShell Core)
- GitHub Personal Access Token (PAT) with `repo` scope

---

## Quick Start

```powershell
# 1. Set your GitHub PAT and repository
$env:GH_PAT = "ghp_YourTokenHere"
$env:REPO = "adamskriver/GalleryMD"

# 2. Generate registration token
.\scripts\get-runner-token.ps1

# 3. Start the runner
docker-compose -f docker-compose.runner.yml up -d

# 4. Verify at: https://github.com/adamskriver/GalleryMD/settings/actions/runners
```

---

## Detailed Setup Instructions

### 1. Create a GitHub Personal Access Token

1. Go to **GitHub.com** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a name (e.g., `GalleryMD Runner Token`)
4. Set expiration (30 days, 60 days, or custom)
5. Select scopes:
   - ✅ **repo** (full control of private repositories)
   - ✅ **workflow** (optional but recommended)
6. Click **Generate token**
7. **Copy the token** (format: `ghp_abc123...`) — you cannot see it again

---

### 2. Set Environment Variables

Open PowerShell in this repository folder:

```powershell
cd "Z:\Nineriver Technologies\Dev\GalleryMD"
```

Set your GitHub PAT (replace with your actual token):

```powershell
$env:GH_PAT = "ghp_YourActualTokenHere"
```

Set the repository name:

```powershell
$env:REPO = "adamskriver/GalleryMD"
```

---

### 3. Generate Runner Registration Token

Run the helper script to fetch a registration token from GitHub and create `.env`:

```powershell
.\scripts\get-runner-token.ps1
```

**What it does:**
- Calls the GitHub API to create a short-lived runner registration token
- Writes the token to `.env` (valid for 1 hour)

You should see:
```
✓ Created .env with registration token (expires in 1 hour)
✓ Start the runner with: docker-compose -f docker-compose.runner.yml up -d
```

---

### 4. Start the Runner Container

```powershell
docker-compose -f docker-compose.runner.yml up -d
```

**What happens:**
- Docker pulls the official GitHub Actions runner image (first time only)
- The container registers itself with your repository using the token in `.env`
- The runner starts listening for workflow jobs

---

### 5. Verify the Runner

1. Go to your repository on GitHub:
   - **Settings** → **Actions** → **Runners**
   - Or visit: https://github.com/adamskriver/GalleryMD/settings/actions/runners
2. You should see a runner named `gallerymd-runner` with status **Idle** (green dot)

---

## Using the Runner in Workflows

Update your workflow files to use the self-hosted runner:

```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: echo "Running on self-hosted runner"
```

You can also target specific labels:

```yaml
jobs:
  build:
    runs-on: [self-hosted, docker, windows]
```

---

## Maintenance Commands

### View runner logs
```powershell
docker logs gallerymd-runner
```

### Follow logs in real-time
```powershell
docker logs -f gallerymd-runner
```

### Stop the runner
```powershell
docker-compose -f docker-compose.runner.yml down
```

### Restart the runner
```powershell
docker-compose -f docker-compose.runner.yml restart
```

### Check runner status
```powershell
docker ps | Select-String gallerymd-runner
```

---

## Re-registering the Runner

If the token expires or you need to re-register:

```powershell
# 1. Set environment variables again
$env:GH_PAT = "ghp_YourTokenHere"
$env:REPO = "adamskriver/GalleryMD"

# 2. Get a new registration token
.\scripts\get-runner-token.ps1

# 3. Recreate the container
docker-compose -f docker-compose.runner.yml down
docker-compose -f docker-compose.runner.yml up -d
```

---

## Security Notes

- The `.env` file contains a registration token that expires in 1 hour
- After the runner registers successfully, you can delete `.env` (the runner stays registered)
- Do **not** commit `.env` to version control (add it to `.gitignore`)
- Keep your GitHub PAT secure; do not commit it or share it
- The PAT is only used to generate registration tokens, not stored in containers

---

## Troubleshooting

### Runner doesn't appear in GitHub
- Check logs: `docker logs gallerymd-runner`
- Verify `.env` has `RUNNER_TOKEN` set
- Ensure your PAT has `repo` scope
- Confirm repository name is correct: `adamskriver/GalleryMD`

### Container exits immediately
- The registration token may have expired (valid 1 hour)
- Re-run `.\scripts\get-runner-token.ps1` and restart the container
- Check logs for error messages

### Docker socket permission errors
- Ensure Docker Desktop is running
- On Linux/WSL2, ensure your user is in the `docker` group

### Workflows not picking up the runner
- Ensure your workflow uses `runs-on: self-hosted`
- Check that the runner shows as **Idle** (not **Offline**) in GitHub
- Verify labels match if you're using label filtering

---

## Cleanup

To remove the runner and container:

```powershell
# 1. Stop and remove container
docker-compose -f docker-compose.runner.yml down

# 2. Remove the runner from GitHub Settings → Actions → Runners
# (or it will auto-remove after being offline for 30 days)

# 3. Clean up .env file
Remove-Item .env -ErrorAction SilentlyContinue
```

To remove Docker volumes:

```powershell
docker volume rm gallerymd_runner_work
```

---

## Additional Resources

- [GitHub Actions: Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [GitHub Actions Runner Docker Image](https://github.com/actions/runner)
- [Managing access with personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
