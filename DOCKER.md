# GalleryMD Docker Setup

Consolidated Docker Compose configuration for GalleryMD application and GitHub Actions self-hosted runner.

## 🏗️ Architecture

- **Single `docker-compose.yml`** manages both services
- **Shared network** allows runner and app to communicate
- **Environment-based configuration** via `.env` file
- **Automated deployment** via GitHub Actions workflow

## 🚀 Quick Start

### 1. Get Fresh Runner Token and Start

```powershell
.\Start-GalleryMD.ps1
```

This script will:
- Fetch a fresh runner registration token from GitHub
- Update `.env` with the new token
- Stop any existing containers
- Start both GalleryMD app and runner

### 2. Manual Start (if you already have a valid runner token)

```powershell
docker compose up -d
```

### 3. View Logs

```powershell
# All services
docker compose logs -f

# Just the app
docker compose logs -f gallerymd

# Just the runner
docker compose logs -f runner
```

### 4. Stop Everything

```powershell
docker compose down
```

## 📋 Services

### GalleryMD Application
- **Container**: `gallerymd`
- **Port**: 3003
- **Image**: Built from `Dockerfile` (Deno Alpine)
- **Volumes**: Mounts your local markdown directory as read-only
- **Health Check**: Monitors `/api/status` endpoint

### GitHub Actions Runner
- **Container**: `gallerymd-runner`
- **Image**: `myoung34/github-runner:latest`
- **Purpose**: Executes GitHub Actions workflows on your local machine
- **Docker Access**: Has access to Docker socket for building/deploying

## 🔧 Configuration

All configuration is in `.env`:

```properties
# Repository
REPO=adamskriver/GalleryMD

# Runner Configuration
RUNNER_NAME=gallerymd-runner
LABELS=self-hosted,docker,linux
RUNNER_TOKEN=<auto-updated-by-script>

# Application
MD_ROOT_HOST=Z:/Nineriver Technologies/Dev  # Your local markdown directory
ADMIN_TOKEN=<secure-random-token>
```

## 🔑 Runner Token Management

Runner tokens expire after 1 hour and can only be used once. Use the `Start-GalleryMD.ps1` script to automatically fetch fresh tokens.

**Manual token fetch:**
```powershell
gh api -H "Accept: application/vnd.github+json" `
       -H "X-GitHub-Api-Version: 2022-11-28" `
       "/repos/adamskriver/GalleryMD/actions/runners/registration-token"
```

## 🔄 Deployment Workflow

When you push to `main`, the GitHub Actions workflow:
1. Checks out the latest code on the self-hosted runner
2. Injects `ADMIN_TOKEN` from GitHub Secrets
3. Rebuilds the `gallerymd` container
4. Restarts it with zero downtime
5. Verifies deployment success

## 🧹 Cleanup Old Setup

The old `docker-compose.runner.yml` is no longer needed. Remove it:

```powershell
Remove-Item docker-compose.runner.yml
```

## 📊 Monitoring

Check runner status:
- GitHub UI: https://github.com/adamskriver/GalleryMD/settings/actions/runners
- Local: `docker compose ps`

Check app health:
- Browser: http://localhost:3003
- API: http://localhost:3003/api/status

## 🐛 Troubleshooting

**Runner not showing in GitHub:**
- Token may be expired → Run `.\Start-GalleryMD.ps1` to get fresh token
- Check logs: `docker compose logs runner`

**App not accessible:**
- Check if running: `docker compose ps`
- Check logs: `docker compose logs gallerymd`
- Verify port 3003 is not in use: `netstat -ano | findstr :3003`

**Docker socket permission errors:**
- On Windows: Make sure Docker Desktop is running
- On Linux: Add runner to docker group

## 🔐 Security Notes

- `.env` contains secrets - never commit it (already in `.gitignore`)
- `ADMIN_TOKEN` is stored in GitHub Secrets and injected during deployment
- Runner has Docker socket access - only run trusted workflows
- Markdown directory is mounted read-only for safety
